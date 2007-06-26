//$Id$
//<Class ADom

/*
 * ADOM: Holds a proxy to a DOM
 * Provides convenience methods for obtaining custom views
 * Constructor takes  the   document to view as argument
 */

function ADom (document) {
    this.document_ = document;
    document.adom = this;
    this.root_ = document.documentElement;
    this.current_ = this.root_;
    this.view_ = null;
}

//>
//< Navigators:

/*
 * Reset view.
 * Resets current to point at the root.
 * @return {node} current node.
 */
ADom.prototype.reset = function () {
    this.root_ = this.document_.documentElement;
    return this.current_ = this.root_;
};

/*
 * next: Move to next sibling.
  * @return {node} current node.
 */
ADom.prototype.next = function () {
    return this.current_ = this.current_.nextSibling;
};

/*
 * previous: Move to previous sibling.
  * @return {node} current node.
 */
ADom.prototype.previous = function() {
    return this.current_ = this.current_.previousSibling;
};

/*
 * up: Move to parent.
  * @return {node} current node.
 */
ADom.prototype.up = function () {
    return this.current_ = this.parentNode;
};

/*
 * down: Move to first child
  * @return {node} current node.
 */
ADom.prototype.down = function () {
    return this.current_ = this.current_.firstChild;
};

/*
 * first: Move to first sibling
  * @return {node} current node.
 */
ADom.prototype.first = function () {
  return this.current_ = this.current_.parentNode.firstChild;
};

/*
 * last: Move to last sibling.
  * @return {node} current node.
 */
ADom.prototype.last = function () {
    return this.current_  = this.current_.parentNode.lastChild;
};

/*
 * Move to  document body
  * @return {node} current node.
 */
ADom.prototype.body = function () {
    return this.current_ =  this.document_.body;
};

//>
//<Summarizers:

/*
 * Return HTML for current node.
 *@Return {string}; innerHTML
 */
ADom.prototype.html = function () {
    return this.current_.innerHTML;
};

/*
 * summarize: Summarize current node.
 * @Return {string};
 */
ADom.prototype.summarize = function () {
    var summary = this.current_.tagName +' ';
    summary += 'has ' + this.current_.childNodes.length + 'children ';
    summary += ' with ' + this.current_.innerHTML.length + ' bytes of content.';
    return summary;
};

/*
 * title: return document title
 * @Return  {string}
 */
ADom.prototype.title = function () {
    return this.document_.title;
};

/*
 * Return document being viewed.
 */
ADom.prototype.document = function () {
    return this.document_;
};

/*
 * Return the current node being viewed.
 */
ADom.prototype.current = function () {
    return this.current_;
};

//>
//<RingBuffer:

/*
 *  Implements iteration.
 */
RingBuffer = function (collection) {
  this.collection_ = collection;
  this.index_ = -1;
  this.len_ = collection.length;
};
    
RingBuffer.prototype.next = function () {
  if (this.index_ == this.len_ -1) {
    this.index_ = -1;
  }
  this.index_++;
          return this.collection_.item(this.index_);
};
            
RingBuffer.prototype.previous = function () {
  if (this.index_ == -1 || this.index_ == 0) {
    this.index_ = this.len_;
  }
  this.index_--;
  return this.collection_.item(this.index_);
};

//>
//<Viewers And Visitors:

/*
 * Set view to forms array
 * Return forms array.
 */
ADom.prototype.forms = function () {
    this.view_ = this.document_.forms;
    return this.view_;
};

/*
 * Return current view.
 */
ADom.prototype.view = function () {
    return this.view_;
};

/*
 * find: set view_ to RingBuffer of elements found by name
 */
ADom.prototype.find = function (tagName) {
  return this.view_ = new RingBuffer(this.current_.getElementsByTagName(tagName));
};

/*
 * visit: visit each node in view_ in turn.
 * Optional argument dir if specified visits in the reverse direction.
 */
ADom.prototype.visit = function (dir) {
  if (dir) {
    return this.view_.previous();
  } else  {
    return this.view_.next();
  }
};

//>
//< Eventing:

//>
//< A11y Reflection:

//>
//<repl hookup

/*
 * Update adom pointer in repl to point to current document.
 * @return {ADom}
 */
repl.updateADom = function ()  {
  if (repl.adom == undefined || content.document.adom == undefined) {
    repl.adom = new ADom(content.document);
    return repl.adom;
  }
  if (repl.adom.document_ != content.document) {
    repl.adom = content.document.adom;
    return repl.adom;
  }
  return repl.adom;
};

//>
//<end of file

"loaded adom.js";

// local variables:
// folded-file: t
// end:

//>
