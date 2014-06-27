package classes
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class MusicButton extends Sprite
	{
		private var _v:String;
		private var _n:String;
		private var _b:Boolean = true;
		private var _w:uint = 44;
		private var _txtField:TextField = new TextField();
		public var callback:Function;
		public function MusicButton(n:String="",v:String=""):void
		{
			_n = n;
			_v = v;
			
			_txtField.width = 20;
			_txtField.height = 20;
			_txtField.x = -5;
			_txtField.y = -8;
			_txtField.text = v;
			addChild(_txtField);
			this.mouseChildren = false;
			this.buttonMode = true;
			this.addEventListener(MouseEvent.MOUSE_OVER,onRollOver);
			this.addEventListener(MouseEvent.MOUSE_OUT,onRollOut);
			this.addEventListener(MouseEvent.CLICK,onClick);
			onRollOut();
		}
		public function setEnable(b:Boolean):void{
			_b = b;
			this.buttonMode = _b;
			var tf:TextFormat = new TextFormat;
			tf.color = 0x8a8a8a;
			tf.size = 18;
			//tf.font = "Arial";
			_txtField.setTextFormat(tf);
			onRollOut();
		}
		private function onClick(evt:MouseEvent):void{
			callback(_n);
		}
		private function onRollOver(evt:MouseEvent=null):void{
			with(this.graphics){
				clear();
				if(_b){
					lineStyle(1,0xa8a8a8,1);
					beginFill(0xddeeff,1);
					drawRect(-_w/2,-_w/2,_w,_w);
					endFill();
				}
			}
		}
		private function onRollOut(evt:MouseEvent=null):void{
			with(this.graphics){
				clear();
				if(_b){
					lineStyle(1,0xa8a8a8,1);
					beginFill(0xeeeeff,1);
					drawRect(-_w/2,-_w/2,_w,_w);
					endFill();
					lineStyle(1,0xa8a8a8,0);
					beginFill(0xddeded,0.5);
					drawRect(-_w/2,0,_w,_w/2);
					endFill();
				}
			}
		}
	}
}