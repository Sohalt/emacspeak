<?xml version="1.0" encoding="utf-8"?>
<!--$Id: dtb-page-range.xsl,v 18.7 2003/06/26 23:33:27 raman Exp -->
<!--$

Description: Extract nodes in a specified page range from a
Daisy3 XML file.  Page range is specified via params start and
end.  All nodes appearing between <pagenum>start</pagenum> and
<pagenum>end+1</pagenum> are extracted. All other nodes are
ignored. 

The nodes we want to output are located by computing the 
intersection of two sets A and B:

A: The set of nodes that follow the start page marker
B:The set of nodes that precede the end page marker

Leading and trailing nodes are computed using set:leading and -->
<!--set:trailing
and the final intersection is computed using set:intersection.
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:set="http://exslt.org/sets"
  version="1.0">
  <xsl:param name="start" select="1"/>
  <xsl:param name="end" select="1"/>
  <xsl:param name="base" />
  <xsl:param name="uniquify" select="1"/>
  <xsl:param name="css">revstd.css</xsl:param>
  <xsl:output method="html" indent="yes" encoding="iso8859-15"/>
  <xsl:key name="pageKey" match="pagenum" use="number(text())"/>
  <xsl:template match="/">
      <html>
        <head>
          <link>
            <xsl:attribute name="type"> text/css</xsl:attribute>
            <xsl:attribute name="href" >
              <xsl:value-of select="$css"/>
          </xsl:attribute></link>
          <xsl:element name="base">
            <xsl:attribute name="href">
              <xsl:value-of select="$base"/>
            </xsl:attribute>
          </xsl:element>
          <title>
            Pages
            <xsl:value-of select="$start"/>--<xsl:value-of select="$end"/>
            from  <xsl:value-of select="/dtbook3/head/title"/>
          </title>
        </head>
        <body>
          <xsl:variable name="pages" select="//pagenum"/>
          <xsl:choose>
            <xsl:when test="count($pages)  &gt; 0">
              <xsl:variable name="first"
                select="key('pageKey', $start)"/>
              <xsl:variable name="last"
                select="key('pageKey', $end+1)"/>
            <xsl:for-each select="$first">
            <xsl:variable  name="after" select="following::*"/>
            <xsl:for-each select="$last">
<xsl:variable name="before" select="preceding::*"/>
            <xsl:for-each
              select="set:intersection($before, $after)">
              <xsl:choose>
                <xsl:when test="$uniquify">
                  <!-- the following test is needed to avoid duplicates 
                  but it is linear in size and a very slow solution -->
                  <xsl:if test="not(set:intersection(ancestor::*, $after))">
                    <xsl:copy-of select="."/>
                  </xsl:if>
                  <!-- Still looking for a better solution for the
                  test above -->
                </xsl:when>
                <xsl:otherwise>
                  <!-- this will produce duplicates -->
                  <xsl:copy-of select="."/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
              </xsl:for-each>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <strong>This book has no page boundary markers.</strong>
          </xsl:otherwise>
        </xsl:choose>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
