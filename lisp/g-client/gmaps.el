;;; gmaps.el --- Google Maps
;;;$Id: gmaps.el 8157 2013-02-19 01:31:05Z tv.raman.tv $
;;; $Author: raman $
;;; Description:  Google Maps -> Lisp
;;; Keywords: Google   Maps API
;;{{{  LCD Archive entry:

;;; LCD Archive Entry:
;;; gcal| T. V. Raman |raman@cs.cornell.edu
;;; An emacs interface to Reader|
;;; $Date: 2006/09/28 17:47:44 $ |
;;;  $Revision: 1.30 $ |
;;; Location undetermined
;;; License: GPL
;;;

;;}}}
;;{{{ Copyright:

;;; Copyright (c) 2006 and later, Google Inc.
;;; All rights reserved.

;;; Redistribution and use in source and binary forms, with or without modification,
;;; are permitted provided that the following conditions are met:

;;;     * Redistributions of source code must retain the above copyright notice,
;;;       this list of conditions and the following disclaimer.
;;;     * Redistributions in binary form must reproduce the above copyright notice,
;;;       this list of conditions and the following disclaimer in the documentation
;;;       and/or other materials provided with the distribution.
;;;     * The name of the author may not be used to endorse or promote products
;;;       derived from this software without specific prior written permission.

;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
;;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;;; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
;;; STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
;;; WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
;;; SUCH DAMAGE.

;;}}}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Commentary:
;;{{{  introduction

;;; Implements the Google Maps API

;;}}}
;;{{{  Required modules

(require 'cl)
(declaim  (optimize  (safety 0) (speed 3)))
(require 'g-utils)

;;}}}
;;{{{ Customizations

(defgroup gmaps nil
  "Google Maps"
  :group 'g)

;;}}}
;;{{{ Maps Geo-Coding and Reverse Geo-Coding:

;;; See http://feedproxy.google.com/~r/GoogleGeoDevelopersBlog/~3/0aP4dsogPJ4/introducing-new-google-geocoding-web.html

(defvar gmaps-geocoder-base
  "http://maps.google.com/maps/api/geocode/json?"
  "Base URL  end-point for talking to the Google Maps Geocoding service.")

(defsubst gmaps-geocoder-url (address)
  "Return URL   for geocoding address."
  (declare (special gmaps-geocoder-base))
  (format "%saddress=%s&sensor=false"
          gmaps-geocoder-base address))

(defsubst gmaps-reverse-geocoder-url (address)
  "Return URL   for reverse geocoding location."
  (declare (special gmaps-geocoder-base))
  (format "%slatlng=%s&sensor=false"
          gmaps-geocoder-base address))

;;;###autoload
(defun gmaps-geocode (address &optional raw-p)
  "Geocode given address.
Optional argument `raw-p' returns complete JSON  object."
  (let ((result 
         (g-json-get-result
          (format "%s --max-time 2 --connect-timeout 1 %s '%s'"
                  g-curl-program g-curl-common-options
                  (gmaps-geocoder-url
                   (g-url-encode address))))))
    (unless
        (string= "OK" (g-json-get 'status result))
      (error "Error geo-coding location."))
    (cond
     (raw-p (g-json-get 'results result))
     (t
      (g-json-get 'location 
                  (g-json-get 'geometry
                              (aref (g-json-get 'results result) 0)))))))

;;;###autoload
(defun gmaps-reverse-geocode (lat-long &optional raw-p)
  "Reverse geocode lat-long.
Optional argument `raw-p' returns raw JSON  object."
  (let ((result 
         (g-json-get-result
          (format "%s --max-time 2 --connect-time 1%s '%s'"
                  g-curl-program g-curl-common-options
                  (gmaps-reverse-geocoder-url
                   (format "%s,%s"
                           (g-json-get 'lat lat-long)
                           (g-json-get 'lng   lat-long)))))))
    (unless (string= "OK" (g-json-get 'status result))
      (error "Error reverse geo-coding."))
    (cond
     (raw-p (g-json-get 'results result))
     (t
     (g-json-get 'formatted_address
                 (aref (g-json-get 'results result) 0))))))

;;; Example of use:
;;;###autoload
(defvar gweb-my-location
  nil
  "Geo coordinates --- automatically set by reverse geocoding gweb-my-address")

;;;###autoload
(defcustom gweb-my-address
  nil
  "Location address. Setting this updates gweb-my-location coordinates  via geocoding."
  :type '(choice
          (const :tag "None" nil)
                 (string  :tag "Address"))
  :set  #'(lambda (sym val)
            (declare (special gweb-my-location))
            (when val 
              (setq gweb-my-location (gmaps-geocode val))
              (when (featurep 'emacspeak)
                (emacspeak-calendar-setup-sunrise-sunset)))
            (set-default sym val))
  :group 'gweb)

;;}}}
;;{{{ Maps Directions 

;;; See  https://developers.google.com/maps/documentation/directions/
(defvar gmaps-directions-base
  "http://maps.googleapis.com/maps/api/directions/json?sensor=false&origin=%s&destination=%s&mode=%s&departure_time=%d"
  "Base URL  end-point for talking to the Google Maps directions service.")

(defsubst gmaps-directions-url (origin destination mode)
  "Return URL   for getting directions from origin to destination.
Parameters 'origin' and 'destination' are  be url-encoded."
  (declare (special gmaps-directions-base))
  (format gmaps-directions-base  origin destination
          mode (float-time)))


;;; Places:
;;; https://developers.google.com/places/documentation/
;; 
(defvar gmaps-places-base
  "https://maps.googleapis.com/maps/api/place/%s/json?sensor=false&key=%s"
  "Base URL  end-point for talking to the Google Maps Places service.")

(defsubst gmaps-places-url-base (query-type key)
  "Return URL  for Places services.
Parameter `query-type' is one of nearbysearch or textsearch.
Parameter `key' is the API  key."
  (declare (special gmaps-places-base))
  (format gmaps-places-base  query-type key))
          

;;}}}
;;{{{ Google Maps API V3

;;; See  https://developers.google.com/maps/documentation/directions/
(defvar gmaps-modes '("driving" "walking" "bicycling" "transit")
  "Supported modes for getting directions.")


(defun gmaps-routes (origin destination mode)
  "Return routes as found by Google Maps Directions."
  (let ((result
         (g-json-get-result
          (format "%s --max-time 2 --connect-timeout 1 %s '%s'"
                  g-curl-program g-curl-common-options
                  (gmaps-directions-url
                   (url-hexify-string origin)
                   (url-hexify-string destination)
                   mode)))))
    (cond
     ((string= "OK" (g-json-get 'status result)) (g-json-get 'routes result))
     (t (error "Status %s from Maps" (g-json-get 'status result))))))


;;; https://developers.google.com/places/

(defcustom gmaps-places-key nil
  "Places API  key --- goto  https://code.google.com/apis/console to get one."
  :type '(choice
          (const :tag "None" nil)
          (string :value ""))
  :group 'gmaps)

;;}}}
;;{{{ Maps UI: 



(make-variable-buffer-local 'gmaps-current-location)

(define-derived-mode gmaps-mode special-mode
  "Google Maps Interaction"
  "A Google Maps front-end for the Emacspeak desktop."
  (let ((start (point))
        (inhibit-read-only t))
    (setq buffer-undo-list t)
    (goto-char (point-min))
    (insert "Google Maps Interaction")
    (put-text-property start (point) 'face font-lock-doc-face)
    (insert "\n\f\n")
    (and gweb-my-address (gmaps-set-current-location gweb-my-address))
    (setq header-line-format '("Google Maps: " (:eval (get 'gmaps-current-location 'address))))))

(declaim (special gmaps-mode-map))

(loop for k in
      '(
        ("d" gmaps-driving-directions)
        ("w" gmaps-walking-directions)
        ("t" gmaps-transit-directions)
        ("b" gmaps-bicycling-directions)
        ("n" gmaps-places-nearby)
        ("c" gmaps-set-current-location)
        ("f" gmaps-set-current-filter)
        ("r" gmaps-set-current-radius)
        (" " gmaps-place-details)
        )
      do
      (define-key  gmaps-mode-map (first k) (second k)))

(defvar gmaps-interaction-buffer "*Google Maps*"
  "Google Maps interaction buffer.")

;;;###autoload
(defun gmaps ()
  "Google Maps Interaction."
  (interactive)
  (declare (special gmaps-interaction-buffer))
  (let ((buffer (get-buffer gmaps-interaction-buffer)))
    (cond
     ((buffer-live-p buffer) (switch-to-buffer buffer))
     (t
      (with-current-buffer (get-buffer-create gmaps-interaction-buffer)
        (erase-buffer)
        (gmaps-mode)
        (setq buffer-read-only t))
      (switch-to-buffer gmaps-interaction-buffer)))))

;;}}}
;;{{{ Directions:

(defun gmaps-display-leg (leg)
  "Display a leg of a route."
  (let ((i 1)
        (inhibit-read-only t)
        (start (point)))
    (loop for step across (g-json-get 'steps leg)
          do
          (insert
           (format "%d:\t%-40ss\t%s\t%s\n"
                   i
                   (g-json-get  'html_instructions step)
                   (g-json-get 'text (g-json-get 'distance step))
                   (g-json-get 'text (g-json-get 'duration step))))
          (save-excursion
            (save-restriction
              (narrow-to-region start (point))
              (html2text)))
          (put-text-property start (1- (point))
                             'maps-data step)
          (setq start  (point))
          (incf i))))

(defun gmaps-display-route (route)
  "Display route in a Maps buffer."
  (let ((i 1)
        (inhibit-read-only t)
        (length (length  (g-json-get 'legs route)))
        (leg nil))
    (insert
     (format "Summary: %s\n"
             (g-json-get 'summary route)))
    (cond
     ((= 1 length)
      (setq leg (aref (g-json-get 'legs route) 0))
      (insert (format "From %s to %s\n%s\t%s\n"
                      (g-json-get 'start_address leg)
                      (g-json-get 'end_address leg)
                      (g-json-get 'text (g-json-get 'distance leg))
                      (g-json-get 'text (g-json-get 'duration leg))))
      (gmaps-display-leg (aref (g-json-get 'legs route) 0)))
     (t
      (loop for leg across (g-json-get 'legs route)
            do
            (insert (format "Leg:%d: From %s to %s\n"
                            i
                            (g-json-get 'start_address leg)
                            (g-json-get 'end_address)))
            (gmaps-display-leg leg)
            (incf i))))
    (insert
     (format "Warnings: %s\n"
             (g-json-get 'warnings route)))
    (insert
     (format "Copyrights: %s\n\f\n"
             (g-json-get 'copyrights route)))))

(defun gmaps-display-routes (routes)
  "Display routes in Maps interaction buffer."
  (let ((i 1)
        (length (length routes))
        (inhibit-read-only t))
    (cond
     ((= 1 length) (gmaps-display-route (aref routes 0)))
     (t
      (loop for route across routes
            do
            (insert (format  "\nRoute %d\n" i))
            (incf i)
            (gmaps-display-route route))))))


(defun gmaps-driving-directions (origin destination)
  "Driving directions from Google Maps."
  (interactive "sStart Address: \nsDestination Address: ")
  (gmaps-directions origin destination "driving"))

(defun gmaps-walking-directions (origin destination)
  "Walking directions from Google Maps."
  (interactive "sStart Address: \nsDestination Address: ")
  (gmaps-directions origin destination "walking"))

(defun gmaps-bicycling-directions (origin destination)
  "Biking directions from Google Maps."
  (interactive "sStart Address: \nsDestination Address: ")
  (gmaps-directions origin destination "bicycling"))


(defun gmaps-transit-directions (origin destination)
  "Transit directions from Google Maps."
  (interactive "sStart Address: \nsDestination Address: ")
  (gmaps-directions origin destination "transit"))



(defun gmaps-directions (origin destination mode)
  "Display  directions obtained from Google Maps."
  (interactive
   (list
    (read-from-minibuffer "Start Address: ")
    (read-from-minibuffer "Destination Address: ")
    (completing-read "Mode: " gmaps-modes)))
  (unless (eq major-mode 'gmaps-mode)
    (error "Not in a Maps buffer."))
  (let ((inhibit-read-only t)
        (start (point-max))
        (routes (gmaps-routes origin destination mode)))
    (goto-char (point-max))
    (insert (format "%s Directions\n" (capitalize mode)))
        (when routes (gmaps-display-routes routes))
        (goto-char start)))

;;}}}
;;{{{ Places:
(defvar gmaps-current-location nil
      "Current maps location.")

(defun gmaps-set-current-location (address)
  " Set current location."
  (interactive  "sAddress: ")  (declare (special gmaps-current-location))
    (setq gmaps-current-location
          (gmaps-geocode address))
    (put 'gmaps-current-location 'address address))


(defstruct gmaps-places-filter
  types keyword name )
(defvar gmaps-current-filter nil
  "Currently active filter. ")
(make-variable-buffer-local 'gmaps-current-filter)

(defsubst gmaps-places-filter-as-params (filter)
  "Convert filter structure into URL  params."
  (let ((keyword (gmaps-places-filter-keyword filter))
        (name (gmaps-places-filter-name filter))
        (types (gmaps-places-filter-types filter)))
    (format "%s%s%s"
            (if keyword (format "&keyword=%s" keyword) "")
            (if name (format "&name=%s" name) "")
            (if types (format "&types=%s" (mapconcat #'identity types "|")) ""))))    

(defsubst gmaps-places-filter-as-string (filter)
  "Convert filter structure into display-friendly string."
  (let ((keyword (gmaps-places-filter-keyword filter))
        (name (gmaps-places-filter-name filter))
        (types (gmaps-places-filter-types filter)))
    (format "%s%s%s"
            (if keyword (format "Keyword: %s" keyword) "")
            (if name (format "Name: %s" name) "")
            (if types (format "Types: %s" (mapconcat #'identity types "|")) ""))))

(defun gmaps-set-current-filter (&optional all)
  "Set up filter in current buffer.
Optional interactive prefix arg prompts for all filter fields."
  (interactive "P")
  (declare (special gmaps-current-filter))
  (cond
   (all
  (let ((name (read-string "Name: " ))
        (keyword (read-string "Keyword: "))
        (types (read-string "Types: ")))
    (when (= (length name) 0) (setq name nil))
    (when (= (length keyword) 0) (setq keyword nil))
    (setq gmaps-current-filter
          (make-gmaps-places-filter
           :name name
           :keyword keyword
           :types (split-string types)))))
   (t
    (setq gmaps-current-filter
          (make-gmaps-places-filter
           :name nil
           :keyword nil
           :types (split-string  (read-string "Types: ")))))))


(defvar gmaps-current-radius  500
  "Radius  to use for places search.")

(make-variable-buffer-local 'gmaps-current-radius)

(defun gmaps-set-current-radius  (radius)
  "Set current radius"
  (interactive "nRadius: ")
  (declare (special gmaps-current-radius))
  (setq gmaps-current-radius radius))

    
    
(defun gmaps-places-nearby (&optional clear-filter)
  "Find places near current location.
Uses default radius. optional interactive prefix arg clears any active filters."
  (interactive "P")
  (declare (special g-curl-program g-curl-common-options
                    gmaps-current-location gmaps-current-filter
                    gmaps-places-key
                    gmaps-places-radius))
  (unless gmaps-current-location (error "Set current location."))
  (and clear-filter (setq gmaps-current-filter nil))
  (goto-char (point-max))
  (let ((start nil)
        (inhibit-read-only t)
        (result
         (g-json-get-result
          (format "%s --max-time 2 --connect-timeout 1 %s '%s'"
                  g-curl-program g-curl-common-options
                  (format "%s&%s&%s%s"
                          (gmaps-places-url-base "nearbysearch" gmaps-places-key)
                          (format "location=%s,%s"
                                  (g-json-get 'lat gmaps-current-location) (g-json-get 'lng gmaps-current-location))
                          (format "radius=%s" gmaps-current-radius)
                          (if gmaps-current-filter
                              (gmaps-places-filter-as-params gmaps-current-filter)
                            ""))))))
    (cond
     ((string= "OK" (g-json-get 'status result))
      (goto-char (point-max))
      (setq start (point))
      (insert
       (format "Places within %sm of  %s\n"
               gmaps-current-radius
               (get 'gmaps-current-location 'address)))
      (when gmaps-current-filter
        (insert (format "Filter: %s\n"
                        (gmaps-places-filter-as-string gmaps-current-filter))))
      (gmaps-display-places (g-json-get 'results result))
      (goto-char start))
     ((string= "ZERO_RESULTS"  (g-json-get 'status result))
      (insert
       (format "No places within %sm  matching %s.\n"
                      gmaps-current-radius
                      (gmaps-places-filter-as-string gmaps-current-filter))))
     (t (error "Status %s from Maps" (g-json-get 'status
                                                 result))))))

(defun gmaps-display-places (places)
  "Display places in Maps interaction buffer."
  (let ((length (length places))
        (inhibit-read-only t))
    (cond
     ((= 1 length) (gmaps-display-place (aref places 0)))
     (t
      (loop for place across places
            do
            (gmaps-display-place place))))))
(defsubst gmaps-colonize-timestring (timestring)
  "Insert `:' to turn 0800 into 08:00. "
  (format "%s:%s"
          (substring timestring 0 2)
          (substring timestring 2)))

(defun gmaps-hours-for-day (hours &optional day)
  "Display hours.Day defaults to today."
  (or day (setq day  (read-number "Week Day: 0 for Sunday: ")))
  (let ((open nil)
        (close nil)
        (weekday
         (aref
          '["Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday"]
          day)))
    (setq open
          (find-if 
           #'(lambda (h)
               (= day (g-json-lookup "open.day" h))) hours)
          close
          (find-if
           #'(lambda (h) (= day (g-json-lookup "close.day" h)) ) hours))
    (format "%s Open: %s, Close: %s"
            weekday 
             (gmaps-colonize-timestring (g-json-lookup "open.time" open))
             (gmaps-colonize-timestring (g-json-lookup "close.time" close)))))

(defun gmaps-display-places-hours (hours)
  "Display opening/closing hours."
  (message (gmaps-hours-for-day hours (read-number "Week Day (0 for Sunday): "))))

(defun gmaps-display-place-details (details)
  "Insert place details."
  (goto-char (line-end-position))
  (insert "\n")
  (let ((start (point))
        (hours (g-json-get 'periods (g-json-get 'opening_hours details)))
        (open (g-json-get 'open_now (g-json-get 'opening_hours details)))        
        (website (g-json-get 'website details))
        (url (g-json-get 'url details))
        (rating (g-json-get 'rating details))
        (price (g-json-get 'price_level  details))
        (phone  (g-json-get 'international_phone_number details))
        (address (g-json-get 'formatted_address details)))
    (when hours
      (let ((today (gmaps-hours-for-day hours (read (format-time-string "%w")))))
            (insert-text-button
             "[Hours]\t"
             'hours hours
             'action
             #'(lambda (b) (gmaps-display-places-hours  (button-get b 'hours))))
        (insert (format "%s\t" today))))
    (when website
      (insert-text-button "[WebSite]\t"
                          'url-link website
                          'action #'(lambda (b) (browse-url
                                                 (button-get b
                                                             'url-link)))))
    (when url
      (insert-text-button "[Places URL]\n"
                          'url-link url
                          'action #'(lambda (b) (browse-url (button-get b 'url-link)))))
    (when (or address phone)
    (insert (format "%s\t%s\n" address  phone)))
    (insert (format "Open: %s\tRating: %s\tPrice: %s\n"
                    (if open "Yes" "No")
                    (or rating "N/A")
                    (or price "N/A")))
    (indent-rigidly start  (point) 4)
    (put-text-property start (point)
                       'place-details details)
    (goto-char start)))
      

(defun gmaps-display-place (place)
  "Display place in Maps buffer."
  (let ((inhibit-read-only t)
        (start (point)))
    (insert
     (format "%s\t%s\t%s\n"
             (g-json-get  'name place)
             (g-json-get 'types place)
             (g-json-get 'vicinity place)))
    (put-text-property start (1- (point))
                       'maps-data place)))

(defun gmaps-place-details ()
  "Display details for place at point."
  (interactive)
  (declare (special g-curl-program g-curl-common-options
                    gmaps-places-key))
  (unless (eq major-mode 'gmaps-mode)
    (error "Not in a Google Maps buffer."))
  (unless  (get-text-property  (point) 'maps-data)
    (error "No maps data at point."))
  (let* ((start nil)
        (inhibit-read-only t)
        (place-ref
         (g-json-get 'reference (get-text-property (point)'maps-data )))
        (result
         (and place-ref
              (g-json-get-result
               (format "%s --max-time 2 --connect-timeout 1 %s '%s'"
                       g-curl-program g-curl-common-options
                       (format "%s&%s&%s"
                               (gmaps-places-url-base "details" gmaps-places-key)
                               (format "reference=%s" place-ref)
                               "extensions=review_summary"))))))
    (cond
                                                                     ((string= "OK" (g-json-get 'status result))
      (put-text-property (line-beginning-position) (line-end-position)
                         'place-details t)
      (gmaps-display-place-details (g-json-get 'result result)))
     (t (error "Status %s from Maps" (g-json-get 'status result))))))

;;}}}
(provide 'gmaps)
;;{{{ end of file

;;; local variables:
;;; folded-file: t
;;; byte-compile-dynamic: nil
;;; end:

;;}}}
