<?xml version="1.0"?>
<!-- { introduction -->
<!--
Author: T. V. Raman <raman@cs.cornell.edu>
Copyright: (C) T. V. Raman, 2001 - 2002,   All Rights Reserved.
License: GPL
Description: Factor out nested tables to the end of document.
Each nested table is replaced with an anchor that links to
the  actual table which appears in a final section of the
document.

The default mode, which is the first pass, passes everything
except tables unmodified.

Tables are matched by rule match = //tables//table 
which creates the required anchor element, deferring the
copying out of the table to the second-pass.

During the second pass, nested tables get recursively
processed by calling apply-templates which by default
applies rules from the first pass.


We then perform a second-pass using a for-each iterator over
nodeset //table//table.
Compare this with 2pass-unravel-tables.xsl which uses a
named mode 'second-pass'
instead of a for-each iterator.
Using for-each allows this style to correctly number the
nested tables during the second-pass; this numbering can be
used as the table-index for extract-tables.xsl.

We sort the nested tables before they are output so the most
relevant tables bubble to the top.
-->
<!-- } -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
<xsl:param name="base"/>
  <xsl:output method="html" indent="yes" encoding="iso8859-15"/>
  <xsl:include href="identity.xsl"/>
<!-- { html body  -->
<!-- nuke these -->
  <xsl:template match="//script|//meta"/>
<xsl:template match="/html/head">
<head>
<xsl:apply-templates select="title"/>
      <xsl:if test="string-length($base) &gt; 0">
<xsl:element name="base">
<xsl:attribute name="href">
<xsl:value-of select="$base"/>
        </xsl:attribute>
      </xsl:element>
      </xsl:if>
    </head>
  </xsl:template>
  <xsl:template match="/html/body">
    <xsl:element name="body">
      <xsl:apply-templates select="@*"/>
      <xsl:if test="count(//table//table)  &gt; 0">
        <table>
          <caption>
            <a href="#__about_sorted_tables">Tables Sorted</a>
          </caption>
          <tr>
            <td>
              <a href="#__nested_tables"><xsl:value-of select="count(//table)"/> 
tables of which 
<xsl:value-of select="count(//table//table)"/>
are nested</a>
            </td>
          </tr>
        </table>
      </xsl:if>
      <xsl:apply-templates/>
      <xsl:if test="count(//table//table)  &gt; 0">
        <h2>
          <a name="__nested_tables" id="__nested_tables"><xsl:value-of select="count(//table//table)"/>
Nested Tables </a>
        </h2>
        <xsl:for-each select="//table//table">
          <xsl:sort select="count(.//span|.//text()|.//p)" order="descending"/>
          <xsl:sort select="count(.//table)" data-type="number" order="ascending"/>
<!--<xsl:sort select="@width" order="descending"/>-->
<!--
<p> sorting keys:
Text <xsl:value-of select="count(.//text() | .//p)"/>
table width: <xsl:value-of select="@width"/>
        </p>
-->
          <h2><xsl:element name="a"><xsl:attribute name="href">
            #src-<xsl:value-of select="generate-id(.)"/>
          </xsl:attribute><xsl:attribute name="name"><xsl:value-of select="generate-id(.)"/></xsl:attribute><em>Table <xsl:value-of select="position()"/> </em><br/></xsl:element><xsl:value-of select="count(./tr)"/> Rows 
 And <xsl:value-of select="count(./tr/td)"/> Cells
        </h2>
          <xsl:element name="table">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates/>
          </xsl:element>
        </xsl:for-each>
        <h2>
          <a name="__about_sorted_tables">About This Style</a>
        </h2>
        <p>
        Note that nested tables have been moved to  section <a href="#__nested_tables">nested tables</a>.
        The table cell that contained the nested table has been
        replaced with a hyperlink that navigates to the actual
        table. If the author has provided a summary and or
        caption for the nested table, those will be displayed
        as the hyperlink text.
Lacking a summary attribute, I have generated hyperlinks of
        the form row-count,cell-count.
I have sorted them  so the most
      relevant tables occur first.
Sort keys were number of text nodes in a table and the width
        of the table (where specified).
        </p>
      </xsl:if>
    </xsl:element>
  </xsl:template>
  <xsl:template match="//table//table">
    <xsl:variable name="rows" select="count(./tr)"/>
    <xsl:variable name="cols" select="count(./tr/td)"/>
    <xsl:element name="a">
      <xsl:attribute name="href">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="generate-id(.)"/>
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:text>src-</xsl:text>
        <xsl:value-of select="generate-id(.)"/>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="@summary">
          <xsl:value-of select="@summary"/>
        </xsl:when>
        <xsl:when test="$rows = 1 and $cols = 1">
          <xsl:apply-templates select="./tr/td/*"/>
        </xsl:when>
        <xsl:otherwise>
[<xsl:value-of select="$rows"/>, <xsl:value-of select="$cols"/>]
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text> </xsl:text>
    </xsl:element>
  </xsl:template>
<!-- } -->
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