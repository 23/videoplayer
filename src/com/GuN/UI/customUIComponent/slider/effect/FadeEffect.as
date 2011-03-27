package com.GuN.UI.customUIComponent.slider.effect
{
	import mx.controls.Alert;
	import mx.effects.Tween;
	import mx.effects.effectClasses.TweenEffectInstance;

	public class FadeEffect extends TweenEffectInstance
	{
		public var show:Boolean = true;
		
		public function FadeEffect(target:*)
		{
			super(target);
		}
		
		override public function play():void {
            super.play();
            var tween:Tween = 
                createTween(this, show?0:1, show?1:0, 500);  
        }
        
        override public function onTweenUpdate(val:Object):void {
            target.alpha = val;
        }
        
        override public function onTweenEnd(val:Object):void {
            super.onTweenEnd(val);
            this.stop();
        }
		
		
	}
}