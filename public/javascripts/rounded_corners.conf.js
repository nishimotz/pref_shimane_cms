function initRoundCorner(){
    settings = {
        tl: { radius: 8 },
        tr: { radius: 8 },
        bl: { radius: 8 },
        br: { radius: 8 },
        // antiAlias should be false to force IE to change color.
        // Or else, we get an rounded_corner javascript error.
        antiAlias: false,
        autoPad: true,
        validTags: ["div"] };

    var myBoxObject1 = new curvyCorners(settings, "round_corner");
    myBoxObject1.applyCornersToAll();
}
