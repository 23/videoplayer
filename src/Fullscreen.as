import flash.display.StageDisplayState;
[Bindable]
public var inFullScreen:Boolean = false;

private function toggleFullScreen():void{
	stage.displayState = (inFullScreen ? StageDisplayState.NORMAL : StageDisplayState.FULL_SCREEN);
	inFullScreen = !inFullScreen;
}