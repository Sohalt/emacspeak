<?xml version="1.0"?>
<!--
Author: T. V. Raman <raman@cs.cornell.edu>
Copyright: (C) T. V. Raman, 2001 - 2002,   All Rights Reserved.
License: GPL
Transform KML to speakable XHTML
-->

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:kml="http://earth.google.com/kml/2.0">
  <xsl:output encoding="iso8859-15"
              method="html"  indent="yes"/>
  
  <xsl:template match="kml:Document|kml:Folder">
    <html>
      <head>
        <title><xsl:value-of select="kml:name"/></title>
      </head>
      <body>
        <h1><xsl:value-of select="kml:name"/></h1>
        <ul>
          <xsl:apply-templates select="kml:Placemark"/>
        </ul>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="kml:Placemark">
    <li>
      <em><xsl:value-of select="kml:name"/></em>
      <xsl:value-of select="kml:description"
                    disable-output-escaping="yes"/>
<xsl:value-of select="kml:Snippet"
                    disable-output-escaping="yes"/>
      <xsl:value-of select="kml:address"
                    disable-output-escaping="yes"/><xsl:if test="kml:LookAt/kml:heading">
        Heading: <xsl:value-of select="kml:LookAt/kml:heading"/>
      </xsl:if>
    </li>
  </xsl:template>
  
  
</xsl:stylesheet>
<!--
    Local Variables:
    mode: xae
    sgml-indent-step: 2
    sgml-indent-data: t
    sgml-set-face: nil
    sgml-insert-missing-element-comment: nil
    folded-file: t
    End:
--> 
