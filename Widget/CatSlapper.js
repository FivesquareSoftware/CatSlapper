var updateTimer;

function setup() {
    logMessage("setup()");
    if(window.widget) {
        widget.onshow = onshow;
        widget.onhide = onhide;
    }
    //updateDisplay();
    //updateTimer = setInterval("updateDisplay()",10000);
}

function onshow() {
    logMessage("onshow()");
    updateDisplay();
    updateTimer = setInterval("updateDisplay()",5000);
}

function onhide() {
    logMessage("onhide()");
    clearInterval(updateTimer);
}

function updateDisplay() {
    updateFields();
    setIndicators();
}

function updateFields() {
    if(CatSlapper) {
        if(CatSlapper.isOpen()) {
             setField("name", CatSlapper.selectedKittyName());
             setField("status", CatSlapper.selectedKittyStatusText());
        } else {
            setField("status","CatSlapper is not open");
        }
    } else {
        setField("status", "Could not load CatSlapper widget plugin");
    }
}

function setField(name, value) {
    document.getElementById(name).innerHTML = value;
}

function setIndicators() {
    if(CatSlapper && CatSlapper.isOpen()) {
        if(CatSlapper.selectedKittyIsRunning()) {
            document.images["on_indicator"].src = "on.png";
            document.images["off_indicator"].src = "off.png"
        } else {
            document.images["on_indicator"].src = "off.png";
            document.images["off_indicator"].src = "on.png"
        }
    }
}

function toggle() {
    if(CatSlapper) 
        CatSlapper.toggleSelectedKitty();
}

function restart() {
    if(CatSlapper)
        CatSlapper.restartSelectedKitty();
}

function logMessage(msg) {
    if(CatSlapper) 
        CatSlapper.logMessage(msg);
}





