<?xml version="1.0" ?>
<!--
Author: T. V. Raman <raman@cs.cornell.edu>
Copyright: (C) T. V. Raman, 2001 - 2002,   All Rights Reserved.
License: GPL
Description: Show list of anchors.
-->

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  
  <xsl:output method="html" indent="yes"
              encoding="iso8859-15"/>
  
  <xsl:include href="identity.xsl"/>
<!-- {nuke these elements. --> 

<xsl:template match="script|meta|link"/>

<!-- } -->
<!-- {html body  --> 

<xsl:template match="/html/body">
<table>
<caption>Anchors View</caption>
<tr>
<td><a href="#__about_this_style">About This Style</a></td>
    </tr></table>
<ul>
<xsl:apply-templates select="//a"/>
</ul>
<h2><a name="__about_this_style">About This Style</a></h2>
<p>This style produces a list of anchors found in the document.</p>
</xsl:template>

<xsl:template match="a">
<li>
<xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
</li>
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
