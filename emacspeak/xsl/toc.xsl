<?xml version="1.0" ?>
<!--Author: T. V. Raman <raman@cs.cornell.edu>
Description: Generate Table of contents
-->

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="html" indent="yes"/>
  
  <xsl:include href="identity.xsl"/>
  <!-- {nuke these elements. --> 

    <xsl:template match="script|meta|link"/>

    <!-- } -->
  <!-- {contents  --> 
    <xsl:template match="/html/body">
      <h1>Table Of Contents</h1>
      <ol>
        <xsl:apply-templates select="//h1|//h2|//h3"
                             mode="toc"/>
      </ol>
      <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="//h1|//h2|//h3" mode="toc">
<li>
        <xsl:element name="a">
          <xsl:attribute name="href">
            <xsl:text>#</xsl:text><xsl:value-of select="generate-id(.)"/>
          </xsl:attribute>
          <xsl:apply-templates/>
        </xsl:element>
    </li>
    </xsl:template>

    <xsl:template match="//h1|//h2|//h3" >
      <xsl:element name="{name(.)}">
        <xsl:apply-templates select="@*"/>
        <xsl:element name="a">
          <xsl:attribute name="name">
            <xsl:value-of select="generate-id(.)"/>
          </xsl:attribute>
          <xsl:apply-templates/>
        </xsl:element>
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
