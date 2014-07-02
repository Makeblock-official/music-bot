package
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.net.SharedObject;
	import flash.net.getClassByAlias;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	
	import classes.MusicButton;
	
	import fl.controls.Button;
	import fl.controls.CheckBox;
	import fl.controls.ComboBox;
	import fl.controls.Label;
	import fl.controls.TextArea;
	import fl.controls.TextInput;
	import fl.data.DataProvider;
	import fl.events.ComponentEvent;
	import fl.managers.StyleManager;
	
	import managers.SerialManager;
	
	public class MusicBot extends Sprite
	{
		private var _combobox_port:ComboBox = new ComboBox;
		private var _combobox_board:ComboBox = new ComboBox;
		private var _label_port:Label = new Label;
		private var _label_board:Label = new Label;
		private var _button_upgrade:Button = new Button;
		private var _button_connect:Button = new Button;
		private var _text_auto:TextField = new TextField;
		private var _label_auto:Label = new Label;
		private var _label_interval:Label = new Label;
		private var _text_interval:TextInput = new TextInput;
		private var _check_auto:CheckBox = new CheckBox;
		private var _check_ultrasonic:CheckBox = new CheckBox;
		private var _isEnableInput:Boolean = true;
		private var _controls:Array = [];
		private var _positions:Array = [];
		private var _labels:Array = ["串口","","型号","","升级固件","连接串口","自动弹奏","","间隔（毫秒）","400","自动演奏","开启超声波"];
		private var _music_buttons:Array = ["1","2","3","4","5","6","7","Q","W","E","R","T","Y","U","I"];
		private var _music_labels:Array = ["1","2","3","4","5","6","7","1","2","3","4","5","6","7","1"];
		private var _music_value:Object = {1:1,2:2,3:3,4:4,5:5,6:6,7:7,
										   q:8,w:9,e:10,r:11,t:12,y:13,u:14,i:15};
		[SWF(width="1024",height="360")]
		
		public function MusicBot()
		{
			_controls.push(_label_port);
			_controls.push(_combobox_port);
			_controls.push(_label_board);
			_controls.push(_combobox_board);
			_controls.push(_button_upgrade);
			_controls.push(_button_connect);
			_controls.push(_label_auto);
			_controls.push(_text_auto);
			_controls.push(_label_interval);
			_controls.push(_text_interval);
			_controls.push(_check_auto);
			_controls.push(_check_ultrasonic);
			
			var tf:TextFormat = new TextFormat();
			tf.size = 13;
			StyleManager.setStyle("textFormat", tf);
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.frameRate = 30;
			stage.addEventListener(Event.RESIZE,onResized);
			_combobox_board.addItem({label:"Leonardo",data:"leonardo"});
			_combobox_board.addItem({label:"Uno",data:"uno"});
			var so:SharedObject = SharedObject.getLocal("makeblock","/");
			if(SerialManager.sharedManager().board=="uno"){
				_combobox_board.selectedIndex = 1;
			}
			if(so.data.interval==undefined){
				so.data.interval = 400;
				so.flush(200);
			}
			_combobox_board.addEventListener(Event.CHANGE,onChangedBoard);
			_check_ultrasonic.enabled = false;
			updatePorts();
			checkUpgradeState();
			_button_connect.addEventListener(MouseEvent.CLICK,onClickConnect);
			_button_upgrade.addEventListener(MouseEvent.CLICK,onClickUpgrade);
			_combobox_port.addEventListener(Event.OPEN,onShowPorts);
			_combobox_port.addEventListener(MouseEvent.CLICK,onShowPorts);
			stage.addEventListener(KeyboardEvent.KEY_UP,onKeyUp);
			_text_auto.addEventListener(FocusEvent.FOCUS_IN,onFocusIn);
			_text_auto.addEventListener(FocusEvent.FOCUS_OUT,onFocusOut);
			_text_interval.addEventListener(Event.CHANGE,onIntervalChanged);
			_text_interval.addEventListener(FocusEvent.FOCUS_IN,onFocusIn);
			_text_interval.addEventListener(FocusEvent.FOCUS_OUT,onFocusOut);
			_check_ultrasonic.addEventListener(Event.CHANGE,onChangeUltrasonic);
			var timer:Timer = new Timer(10);
			timer.addEventListener(TimerEvent.TIMER,onTimerLoop);
			timer.start();
		}
		private function onFocusIn(evt:FocusEvent):void{
			_isEnableInput = false;
		}
		private function onFocusOut(evt:FocusEvent):void{
			_isEnableInput = true;
		}
		private function onResized(evt:Event):void{
			stage.removeEventListener(Event.RESIZE,onResized);
			var sw:uint = stage.stageWidth;
			var sh:uint = stage.stageHeight;
			
			var bg:Sprite = new Sprite;
			with(bg.graphics){
				clear();
				beginFill(0xDDEEFF,1);
				drawRect(0,0,sw,sh);
				endFill();
			}
			addChild(bg);
			var bg_txt:TextField = new TextField;
			bg_txt.width = sw;
			bg_txt.height = sh;
			bg_txt.selectable = false;
			addChild(bg_txt);
			_text_auto.condenseWhite = true; 
			_text_auto.background = true;
			_text_auto.backgroundColor = 0xffffff;
			_text_auto.border = true;
			_text_auto.borderColor = 0xa8a8a8;
			_text_auto.width = sw-210;
			_text_auto.height = 80;
			_text_auto.type = TextFieldType.INPUT;
			_text_auto.multiline = true;
			_text_auto.wordWrap = true;
			_text_auto.alwaysShowSelection = true;
			_text_auto.addEventListener(Event.CHANGE,onTextChanged);
			_positions.push(new Point(sw-170,30));
			_positions.push(new Point(sw-130,30));
			_positions.push(new Point(sw-170,70));
			_positions.push(new Point(sw-130,70));
			_positions.push(new Point(sw-130,110));
			_positions.push(new Point(sw-130,150));
			_positions.push(new Point(25,170));
			_positions.push(new Point(25,200));
			_positions.push(new Point(25,290));
			_positions.push(new Point(115,290));
			_positions.push(new Point(sw-266,290));
			_positions.push(new Point(sw-276,168));
			var text_help:TextField = new TextField;
			text_help.width = 140;
			text_help.height = 100;
			var tf:TextFormat = new TextFormat;
			tf.color = 0x006699;
			tf.size = 14;
			tf.font = "Arial";
			text_help.multiline = true;
			text_help.selectable = false;
			text_help.htmlText = "<a href='http://bbs.makeblock.cc/thread-252-1-1.html?musicbot'>帮助</a><br/><br/><a href='http://bbs.makeblock.cc/forum-39-1.html?musicbot'>Scratch机器人</a><br/><br/><a href='http://makeblock.cc/?musicbot'>Makeblock官网</a>";
			text_help.setTextFormat(tf);
			text_help.x = sw - 130;
			text_help.y = 198;
			addChild(text_help);
			for(var i:uint=0;i<_controls.length;i++){
				_controls[i].x = _positions[i].x;
				_controls[i].y = _positions[i].y;
				if(getQualifiedClassName(_controls[i]).indexOf("Label")>-1){
					_controls[i].text = _labels[i];
				}else if(getQualifiedClassName(_controls[i]).indexOf("Button")>-1){
					_controls[i].label = _labels[i];
				}else if(getQualifiedClassName(_controls[i]).indexOf("ComboBox")>-1){
				}else if(getQualifiedClassName(_controls[i]).indexOf("TextInput")>-1){
					_controls[i].text = _labels[i];
				}else if(getQualifiedClassName(_controls[i]).indexOf("CheckBox")>-1){
					_controls[i].label = _labels[i];
				}
				if(!this.contains(_controls[i])){
					addChild(_controls[i]);
				}
			}
			var so:SharedObject = SharedObject.getLocal("makeblock","/");
			_text_interval.text = so.data.interval;
			drawButtons();
		}
		private function onTextChanged(evt:Event=null):void{
			
			var tf:TextFormat = new TextFormat;
			tf.size = 24;
			tf.font = "Arial";
			tf.color = 0x4a4a4a;
			_text_auto.setTextFormat(tf);
		}
		private function drawButtons():void{
			for(var i:uint=0;i<_music_buttons.length;i++){
				var mButton:MusicButton = new MusicButton(_music_buttons[i],_music_buttons[i]);
				addChild(mButton);
				mButton.x = i*54+50;
				mButton.y = 50;
				mButton.callback = buttonCallback;
				mButton = new MusicButton(_music_labels[i],_music_labels[i]);
				mButton.setEnable(false);
				addChild(mButton);
				mButton.x = i*54+46;
				mButton.y = 120;
				if(i<7){
					
					mButton = new MusicButton(".",".");
					mButton.setEnable(false);
					addChild(mButton);
					mButton.x = i*54+48;
					mButton.y = 130;
				}
				if(i>13){
					mButton = new MusicButton(".",".");
					mButton.setEnable(false);
					addChild(mButton);
					mButton.x = i*54+48;
					mButton.y = 100;
				}
			}
		}
		private function updatePorts():void{
			var dp:DataProvider = new DataProvider();
			var list:Array = SerialManager.sharedManager().list;
			for(var i:uint=0;i<list.length;i++){
				dp.addItem({label:list[i],data:list[i]});
			}
			_combobox_port.dataProvider = dp;
		}
		private function onClickConnect(evt:MouseEvent):void{
			if(_button_connect.label == "连接串口"){
				if(SerialManager.sharedManager().connect(_combobox_port.selectedItem.label)==1){
					_button_connect.label = "断开串口";
					checkUpgradeState();
					_check_ultrasonic.enabled = true;
					var so:SharedObject = SharedObject.getLocal("makeblock","/");
					if(so.data.ultrasonic==undefined){
						so.data.ultrasonic = 1;
						so.flush(200);
					}
					_check_ultrasonic.selected = so.data.ultrasonic==1;
					onChangeUltrasonic();
				}
			}else{
				_check_ultrasonic.enabled = false;
				SerialManager.sharedManager().disconnect();
				checkUpgradeState();
				_button_connect.label = "连接串口";
			}
		}
		private function onClickUpgrade(evt:MouseEvent):void{
			if(SerialManager.sharedManager().isConnected){
				SerialManager.sharedManager().connect("upgrade");
				_button_connect.label = "连接串口";
			}
		}
		private function onChangedBoard(evt:Event):void{
			SerialManager.sharedManager().connect(_combobox_board.selectedItem.data);
		}
		
		private function onChangeUltrasonic(evt:Event=null):void{
			if(SerialManager.sharedManager().isConnected){
				SerialManager.sharedManager().sendString(_check_ultrasonic.selected?"M":"N");
				var so:SharedObject = SharedObject.getLocal("makeblock","/");
				so.data.ultrasonic = _check_ultrasonic.selected?1:0;
				so.flush(200);
			}
		}
		private function onKeyUp(evt:KeyboardEvent):void{
			if(!_isEnableInput){
				return;
			}
			if(evt.charCode==8){
				if(_text_auto.text.length>0){
					_text_auto.text = _text_auto.text.substr(0,_text_auto.text.length-1);
				}
			}
			if(evt.charCode>20){
				var s:String = String.fromCharCode(evt.charCode);
				sendValue(s);
				if(!_check_auto.selected){
					_text_auto.appendText(s);
					onTextChanged();
				}
			}
		}
		private function onIntervalChanged(evt:Event):void{
			var so:SharedObject = SharedObject.getLocal("makeblock","/");
			so.data.interval = ""+Number(_text_interval.text);
			so.flush(200);
		}
		private function buttonCallback(s:String):void{
			s = s.toLowerCase();
			if(SerialManager.sharedManager().isConnected){
				sendValue(s);
			}
			_text_auto.appendText(s);
			onTextChanged();
		}
		private function checkUpgradeState():void{
			_button_upgrade.enabled = SerialManager.sharedManager().isConnected;
		}
		private function onShowPorts(evt:*):void{
			updatePorts();
		}
		private var _lastTime:Number = 0;
		private var _lastIndex:uint = 0;
		private function onTimerLoop(evt:TimerEvent):void{
			var interval:Number = Number(_text_interval.text);
			if(getTimer()-_lastTime>interval){
				_lastTime = getTimer();
				if(SerialManager.sharedManager().isConnected&&_check_auto.selected){
					if(_lastIndex>_text_auto.text.length-1){
						_lastIndex = 0;
					}
					_text_auto.setSelection(_lastIndex,_lastIndex+1);
					var s:String = _text_auto.text.charAt(_lastIndex);
					sendValue(s);
					_lastIndex++;
				}
			}
		}
		private function sendValue(s:String):void{
			var bytes:ByteArray = new ByteArray;
			if(_music_buttons.indexOf(s.toUpperCase())>-1){
				bytes.writeByte(_music_value[s.toLowerCase()]);
				trace("v:",_music_value[s.toLowerCase()]);
			}else{
				bytes.writeByte(100);
				trace("nv:",100);
			}
			SerialManager.sharedManager().sendBytes(bytes);
		}
	}
}