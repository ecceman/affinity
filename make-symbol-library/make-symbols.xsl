<!--

Converts a list of SVG files into a single SVG containing a
symbol element with each file's body, making the identifiers
inside each symbol unique across the whole document. This
single SVG can be placed into an Inkscape symbols directory,
and will make the symbols available to drag-and-drop into
Inkscape drawings.

Input format:

     <files>
       <file id="valid_identifier1">/entire/pathname/of/file.svg</file>
       <file id="valid2">C:\A\Windows\Path\Works\Too.svg</file>
       ...
     </files>

-->
<!-- started from https://stackoverflow.com/a/52715878 CC BY-SA Tomalak 2018 -->
<!-- (most) namespaces here get inherited by the output's root svg element -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
xmlns:svg="http://www.w3.org/2000/svg"
xmlns="http://www.w3.org/2000/svg"
xmlns:xlink="http://www.w3.org/1999/xlink"
xmlns:serif="http://www.serif.com/"
xmlns:dc="http://purl.org/dc/elements/1.1/" 
xmlns:cc="http://creativecommons.org/ns#"         
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
>

    <xsl:output method="xml" version="1.0" encoding="utf-8"
                indent="yes"
                doctype-public="-//W3C//DTD SVG 1.1//EN"
                doctype-system="http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd" />

    <xsl:template match="/">
      <svg width="100%" height="100%" viewBox="0 0 300 300" version="1.1" xml:space="preserve" style="fill-rule:evenodd;clip-rule:evenodd;stroke-linejoin:round;stroke-miterlimit:1.41421;">
        <title>Affinity</title>
        <desc>ecceman's free 2D symbols for computer network diagrams</desc>
        <metadata>
          <rdf:RDF>
            <cc:Work rdf:about="">
              <dc:format>image/svg+xml</dc:format>
              <dc:type rdf:resource="http://purl.org/dc/dcmitype/StillImage"/>
              <dc:title>Affinity</dc:title>
              <dc:date>2021-07-17</dc:date>
              <dc:creator>
                <cc:Agent>
                  <dc:title>ecceman</dc:title>
                </cc:Agent>
              </dc:creator>
              <dc:rights rdf:resource="https://github.com/ecceman/affinity/blob/master/LICENSE"/>
              <dc:source>https://github.com/ecceman/affinity</dc:source>
              <dc:description>ecceman's free 2D symbols for computer network diagrams</dc:description>
            </cc:Work>
          </rdf:RDF>
        </metadata>
        <defs>

        
          <xsl:apply-templates />

          
        </defs>
      </svg>
    </xsl:template>

    <xsl:template match="/files">
      <xsl:apply-templates />
    </xsl:template>
    
    <xsl:template match="/files/file">
      <!-- my default xmlns for this document is SVG, but only when I
           added a specific svg namespace and used it here did I get
           the proper behavior. -->
      <svg:symbol>
        <xsl:copy-of select="@id" />
        <xsl:copy-of select="document(.)/svg:svg/@viewBox" />
        <xsl:apply-templates select="document(.)/svg:svg/*">
          <xsl:with-param name="idprefix" select="concat(@id,'__')" />
        </xsl:apply-templates>
      </svg:symbol>
    </xsl:template>

    <!-- to combine all these files, we need to make any id's of
         elements inside them unique across the whole collection. so
         we prefix all id attribute values with an idprefix.

         references to those id's at this writing seem to be limited
         to elements with clip-path attributes equal to
         'url(#an-id-value)'. so we fix those references up too.
    -->
    
    <xsl:template match="@id">
      <xsl:param name="idprefix" />
      <xsl:attribute name="id"><xsl:value-of select="$idprefix" /><xsl:value-of select="." /></xsl:attribute>
    </xsl:template>

    <xsl:template match="@clip-path">
      <xsl:param name="idprefix" />
      <xsl:choose>
        <xsl:when test="starts-with(., 'url(#')">
          <xsl:variable name="rest" select="substring-after(., 'url(#')" />
          <xsl:attribute name="clip-path">url(#<xsl:value-of select="$idprefix"/><xsl:value-of select="$rest"/></xsl:attribute>
        </xsl:when>
        <xsl:otherwise><xsl:copy-of select="."/></xsl:otherwise>
      </xsl:choose>
    </xsl:template>
        
    <xsl:template match="@*|node()">
      <xsl:param name="idprefix" />
      <xsl:copy>
        <xsl:apply-templates select="@*|node()">
          <xsl:with-param name="idprefix" select="$idprefix" />
        </xsl:apply-templates>
      </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
