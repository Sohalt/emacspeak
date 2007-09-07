//$Id$
// <Class ADom

/*
 * ADOM: Holds a proxy to a DOM
 * Provides convenience methods for obtaining custom views
 * Constructor takes  the   document to view as argument
 */

function ADom (document) {
    this.document_ = document;
    document.adom = this;
    this.root_ = document.documentElement;
    this.current_ = document.documentElement;
    this.view_ = null;
}

// >
// < Navigators:

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

// >
// <Summarizers:

/*
 * base: Return appropriately encoded <base ../>
 * @return: {String} HTML base element.
 */
ADom.prototype.base = function () {
    return '<base href=\"' + this.document_.baseURI +  '\"/>\n';
};

/*
 * Return HTML for current node.
 * Produces a <base ../> if optional boolean flag gen_base is true.
 *@Return {string}; HTML
 */
ADom.prototype.html = function (gen_base) {
    if (this.current_.tagName.match(/noscript/i)) return '';
    var html ="";
    if (gen_base) {
        html += this.base();
    }
    html +='<' + this.current_.tagName;
    var map = this.current_.attributes;
    if (map  instanceof NamedNodeMap) {
        for (var i = 0; i < map.length; i++) {
            html += ' ' + map[i].name + '=';
            html += '\"' +map[i].value + '\"\n';
        }
    }
    if (this.current_.childNodes.length === 0) {
        return html += '/>\n';
    } else {
        html += '>\n' + this.current_.innerHTML;
        html += '</' + this.current_.tagName +'>\n';
        return html;
    }
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
 * url: Return base URL of document.
 * @return {String} url
 */
ADom.prototype.url = function () {
    return this.document_.baseURI;
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

// >
// <RingBuffer:

/*
 *  Implements iteration.
 */
RingBuffer = function (list) {
    this.list_ = list;
    this.index_ = -1;
    this.len_ = list.length;
};

/*
 * item: Return item at specified index.
 * @return: node.
 */
RingBuffer.prototype.item = function (index) {
    return this.list_.item(this.index);
};


RingBuffer.prototype.next = function () {
    if (this.index_ == this.len_ -1) {
        this.index_ = -1;
    }
    this.index_++;
    return this.list_.item(this.index_);
};
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
RingBuffer.prototype.previous = function () {
    if (this.index_ === -1 || this.index_ === 0) {
        this.index_ = this.len_;
    }
    this.index_--;
    return this.list_.item(this.index_);
};

// >
// <XPathRingBuffer:

/*
 *  Implements RingBuffer.
 */
XPathRingBuffer = function (nodes) {
    this.list_ = nodes;
    this.index_ = -1;
    this.len_ = nodes.snapshotLength;
};
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           

/*
 * item: Return item at specified index.
 * @return: node.
 */
XPathRingBuffer.prototype.item = function (index) {
    return this.list_.snapshotItem(this.index);
};


XPathRingBuffer.prototype.next = function () {
    if (this.index_ == this.len_ -1) {
        this.index_ = -1;
    }
    this.index_++;
    return this.list_.snapshotItem(this.index_);
};
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
XPathRingBuffer.prototype.previous = function () {
    if (this.index_ === -1 || this.index_ === 0) {
        this.index_ = this.len_;
    }
    this.index_--;
    return this.list_.snapshotItem(this.index_);
};

// >
// <XPath:

/*
 * filter: Apply XPath selector to create a filtered view.
 * @return {RingBuffer} of selected nodes suitable for use by visit()
 */

ADom.prototype.filter = function (xpath) {
    var start = this.current_ || this.root_;
    var snap   =
    this.document_.evaluate(xpath,
                            start, null,
                            XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE, null);
    return this.view_ = new XPathRingBuffer(snap);
};

// >
// <Viewers And Visitors:

/*
 * traverse: Traverse nodes that match test and apply action.
 * Arguments:
 * node: Node where we start traversing.
 * test: Predicate
 * Action: Visit action
 * @return: void
 */

ADom.prototype.traverse = function (node, test, action) {
  if(node.nodeType == document.ELEMENT_NODE) {
    if(test(node)) action(node);
    var child = node.firstChild;
    while(child) this.traverse(child, test, action);
  }
};

/*
 * Set view to forms array
 * Return forms array.
 */
ADom.prototype.forms = function () {
    this.view_ = new RingBuffer(this.document_.forms);
    return this.view_;
};
/*
 * locate: set view_ to RingBuffer of elements found by name
 */
ADom.prototype.locate = function (tagName) {
    var start = this.current_ || this.root_;
    return this.view_ = new RingBuffer(start.getElementsByTagName(tagName));
};

/*
 * visit: visit each node in view_ in turn.
 * Optional argument dir if specified visits in the reverse direction.
 */
ADom.prototype.visit = function (dir) {
    if (dir) {
        this.current_ = this.view_.previous();
    } else  {
        this.current_ = this.view_.next();
    }
    // skip empties
    if (this.current_.childNodes.length === 0 && this.current_.attributes.length  === 0) {
        return this.visit(dir);
    } else {
        return this.current_;
    }
};


/*
 * view: Return HTML for all nodes in view_ array
 * @return: {String} HTML
 */
ADom.prototype.view = function () {
    if (this.view_ === null) {
        return this.current_.html(true);
    }
    var html =this.base();
    var len = this.view_.len_;
    for (var i = 0; i < len; i++) {
        this.visit();
        html += this.html();
    }
    return html;
};

// >
// < Eventing:

// >
// < A11y Reflection:

// >
// <repl hookup

/*
 * Update adom pointer in repl to point to current document.
 * @return {ADom}
 */
repl.updateADom = function ()  {
    if (content.document.adom == undefined) {
        // constructor caches adom in content.document
        repl.adom = new ADom(content.document);
    } else {
      repl.adom = content.document.adom;
    }
    return repl.adom;
};

// >
// <end of file

"loaded adom.js";

// local variables:
// folded-file: t
// end:

// >
