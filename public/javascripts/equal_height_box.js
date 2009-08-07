/*
 * EqualHeightBox.js
 *
 * This module set html block elements to equal height on page load.
 *
 * Propartis
 * boxes: A set of boxes whose height to be equalized.
 *
 * Methods
 * constructor: Initialize the object. Take array of elements' ids whose
 * height is to be equalized.
 *
 * apply: Equalise the height of boxes.
 *
 * maxHeight: Return the tallest height among boxes.
 */
 
function getElement(id) {
        if(document.getElementById) {
                return document.getElementById(id);
        } else if(document.all){
                return document.all[id];
        }

}
function EqualHeightBox(boxIds) {
    this.boxes = [];
    for (var i = 0; i < boxIds.length; i++) {
        if (getElement(boxIds[i])) {
            this.boxes.push(getElement(boxIds[i]));
        }
    }
}

// Set boxes height to the highest box's heigt.
EqualHeightBox.prototype.equalize = function() {
    this.unequalize();
    var maxh = this.maxHeight();
    for (var i = 0; i < this.boxes.length; i++) {
            this.boxes[i].style.height = maxh + "px";
    }
};

// Make boxes height changeable on window resize
EqualHeightBox.prototype.unequalize = function() {
    for (var i = 0; i < this.boxes.length; i++) {
            this.boxes[i].style.height = "";
    }
};

// Get height of the tallest box.
EqualHeightBox.prototype.maxHeight = function() {
    var maxh = 0;
    for (var i = 0; i < this.boxes.length; i++) {
        if (maxh < this.boxes[i].offsetHeight) {
            maxh = this.boxes[i].offsetHeight;
        }
    }
    return maxh;
};
