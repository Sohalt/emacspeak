<?xml version="1.0" encoding="utf-8"?>
<!--$Id$-->

<!--
Author: T. V. Raman <raman@cs.cornell.edu>
Copyright: (C) T. V. Raman, 2001 - 2002,   All Rights Reserved.
License: GPL
Transform HTML Object element into an anchor usable in W3.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:output encoding="iso8859-15"
  method="html"  indent="yes"/>
  <xsl:template match="object">
    <strong>Object changed to navigation list.
  </strong>strong>
  <ul>
    <xsl:for-each select="param">
        <xsl:if test="@src">
<li>
<a>
<xsl:attribute name="href">
<xsl:value-of select="@src"/>
              </xsl:attribute>
<xsl:value-of select="@src"/>
            </a></li>
        </xsl:if>
      </xsl:for-each>
    </ul>
  </xsl:template>
  <xsl:template match="/">
    <html>
      <body bgcolor="#FFFFFF">
        <xsl:apply-templates/>
      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>
