package managers
{
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	

	public class SerialManager
	{
		private var slot1:uint = 1
		private var slot2:uint = 2
		
		private var axisX:uint = 1
		private var axisY:uint = 2
		private var axisZ:uint = 3
		
		private var port1:uint = 0x10
		private var port2:uint = 0x20
		private var port3:uint = 0x30
		private var port4:uint = 0x40
		private var port5:uint = 0x50
		private var port6:uint = 0x60
		private var port7:uint = 0x70
		private var port8:uint = 0x80
		private var m1:uint = 0x90
		private var m2:uint = 0xA0
		private var I2C:uint = 0xB0
		private var DIGIPORT:uint = 0xC0
		private var ALOGPORT:uint = 0xD0
		
		private var portEnum:Object = {"Port1":port1,"Port2":port2,"Port3":port3,"Port4":port4,"Port5":port5,"Port6":port6,"Port7":port7,"Port8":port8,"M1":m1,"M2":m2,"I2C":I2C}
		private var slotEnum:Object = {"Slot1":slot1,"Slot2":slot2,"X-Axis":axisX,"Y-Axis":axisY,"Z-Axis":axisZ}
		private var axisEnum:Object = {"X-Axis":axisX,"Y-Axis":axisY,"Z-Axis":axisZ}
		private var dpinEnum:Object = {"D2":0,"D3":1,"D4":2,"D5":3,"D6":4,"D7":5,"D8":6,"D9":7,"D10":8,"D11":9,"D12":10,"D13":11}
		private var apinEnum:Object = {"A0":0,"A1":1,"A2":2,"A3":3,"A4":4,"A5":5}
		private var pinmodeEnum:Object = {"Input":1,"Output":0}
		private var levelEnum:Object = {"Low":0,"High":1,"Off":0,"On":1}
		
		private var firmVersion:Number = 0;
		
		private var VERSION:uint = 0
		private var ULTRASONIC_SENSOR:uint = 1
		private var TEMPERATURE_SENSOR:uint = 2
		private var LIGHT_SENSOR:uint = 3
		private var POTENTIONMETER:uint = 4
		private var JOYSTICK:uint = 5
		private var GYRO:uint = 6
		private var RGBLED:uint = 8
		private var SEVSEG:uint = 9
		private var MOTOR:uint = 10
		private var SERVO:uint = 11
		private var ENCODER:uint = 12;
		private var PIRMOTION:uint = 15;
		private var INFRARED:uint = 16
		private var LINEFOLLOWER:uint = 17;
		private var DIGITAL:uint = 30;
		private var ANALOG:uint = 31;
		private var PWM:uint = 32;
		private var actions:Object = {"run":0x2,"get":0x1,"mode":0x3};
		private var devices:Object = {"lightsensor":LIGHT_SENSOR,
												"motor":MOTOR,
												"servo":SERVO,
												"sevseg":SEVSEG,
												"led":RGBLED,
												"ultrasonic":ULTRASONIC_SENSOR,
												"linefollower":LINEFOLLOWER,
												"potentiometer":POTENTIONMETER,
												"pirmotion":PIRMOTION,
												"gyro":GYRO,
												"infrared":INFRARED,
												"temperature":TEMPERATURE_SENSOR,
												"joystick":JOYSTICK,
												"digital":DIGITAL,
												"analog":ANALOG,
												"pwm":PWM};
		private var moduleList:Array = [];
		private var _currentList:Array = [];
		private static var _instance:SerialManager;
		public var currentPort:String = "";
//		public var _scratch:Scratch;
		private var _board:String = "leonardo";
		public static function sharedManager():SerialManager{
			if(_instance==null){
				_instance = new SerialManager;
			}
			return _instance;
		}
		private var _serial:AIRSerial;
		public function SerialManager()
		{
			_serial = new AIRSerial();
			_serial.addEventListener(Event.CHANGE,onChanged);
			var so:SharedObject = SharedObject.getLocal("makeblock","/");
			if(so.data.board!=undefined){
				_board = so.data.board;
			}
			NativeApplication.nativeApplication.addEventListener(Event.EXITING,onExiting);
		}
		public function get board():String{
			return _board;
		}
//		public function setScratch(scratch:Scratch):void{
//			_scratch = scratch;
//		}
		private function onChanged(evt:Event):void{
			var len:uint = _serial.getAvailable();
			if(len>0){
				var bytes:ByteArray = _serial.readBytes();
				bytes.endian = Endian.LITTLE_ENDIAN;
				if(bytes.length>6){
					bytes.readUnsignedByte();
					bytes.readUnsignedByte();
					var extId:uint = bytes.readUnsignedByte();
					var value:Number = bytes.readFloat();
					if(value<-255||value>1023){
						value = 0;
					}
					trace("value:"+value,"extId:"+extId);	
//					_scratch.extensionManager.reporterCompleted("Makeblock",extId,value);
//					_scratch.extensionManager.reporterCompleted("Makeblock",extId+1,value);
				}
//				for(var i:uint=0;i<bytes.length;i++){
//					trace("0x"+bytes.readUnsignedByte().toString(16));
//				}
			}
			/*
			bytes.readUnsignedByte();
			bytes.readUnsignedByte();
			bytes.readUnsignedByte();
			
			trace("value:"+bytes.readFloat());	
			*/
		}
		public function get isConnected():Boolean{
			return _serial.isConnected;
		}
		private function onExiting(evt:Event):void{
			_serial.dispose();
		}
		public function get list():Array{
			_currentList = _serial.list().split(",").sort();
			return _currentList;
		}
		public function parse(url:String):void{
			var bytes:ByteArray = new ByteArray;
			bytes.endian = Endian.LITTLE_ENDIAN;
			bytes.writeByte(0xff);
			bytes.writeByte(0x55);
			if(url=="reset_all"){
				bytes.writeByte(0x4);
				bytes.writeByte(0x0);
			}else{
				var arr:Array = url.split("/");
				var action:uint = 0;
				var device:uint = 0;
				var port:uint = 0;
				var slot:uint = 0;
				for(var i:uint=0;i<arr.length;i++){
					if(i==0){
						action = actions[arr[0]];
						bytes.writeByte(action);
					}else if(i==1){
						device = devices[arr[1]];
						bytes.writeByte((arr.length-1)+(action==1?0:(device==RGBLED?0:3)));
						bytes.writeByte(device);
					}else{
						if(arr[i].indexOf("Port")>-1||arr[i].indexOf("M1")>-1||arr[i].indexOf("M2")>-1||arr[i].indexOf("I2C")>-1){
							port = portEnum[arr[i]];
							if(url.indexOf("Slot")<0&&url.indexOf("Axis")<0){
								bytes.writeByte(port);
							}
						}else if(arr[i].indexOf("Slot")>-1||arr[i].indexOf("Axis")>-1){
							slot = slotEnum[arr[i]];
							bytes.writeByte(port+slot);
						}else if(arr[i].indexOf("Ext")>-1){
							bytes.writeByte(int(arr[i].split("Ext")[1]));
						}else{
							if(device==RGBLED){
								bytes.writeByte(int(arr[i]));
							}else{
								if((device==DIGITAL||device==ANALOG||device==PWM)&&i==2){
									bytes.writeByte(int(arr[i]));
								}else{
									bytes.writeFloat(Number(arr[i]));
								}
							}
						}
					}
				}
//				bytes.position = 0;
//				for(i=0;i<bytes.length;i++){
//					trace("0x"+bytes.readUnsignedByte().toString(16));
//				}
//				bytes.position = 0;
			}
			trace(url);
			sendBytes(bytes);
		}
		public function sendBytes(bytes:ByteArray):int{
			if(_serial.isConnected)
				return _serial.writeBytes(bytes);
			return 0;
		}
		public function sendString(msg:String):int{
			if(_serial.isConnected)
				return _serial.writeString(msg);
			return 0;
		}
		public function connect(port:String,baudrate:uint=115200):int{
			if(port.indexOf("uno")>-1||port.indexOf("leonardo")>-1){
				_board = port;
				var so:SharedObject = SharedObject.getLocal("makeblock","/");
				so.data.board = port;
				so.flush(200);
				return 0;
			}
			if(_serial.isConnected){
				if(port.indexOf("upgrade")>-1){
					if(_board=="leonardo"){
						_serial.close();
						_serial.open(currentPort,1200);
						_serial.close();
						var timer:Timer = new Timer(500,20);
						timer.addEventListener(TimerEvent.TIMER,checkAvailablePort);
						timer.start();
					}else{
						_serial.close();
						upgradeFirmware();
					}
				}else{
					disconnect();
				}
			}
			if(port.indexOf("COM")>-1){
				var result:int = _serial.open(port,baudrate);
				if(result==0){
					currentPort = port;
				}else{
					currentPort = "";
				}
				return result==0?1:0;
			}
			return 0;
		}
		public function disconnect():void{
			currentPort = "";
			_serial.close();
		}
		private var process:NativeProcess;
		private function checkAvailablePort(evt:TimerEvent):void{
			
			var lastList:Array = _serial.list().split(",");
			for(var i:* in _currentList){
				var index:int = lastList.indexOf(_currentList[i]);
				if(index>-1){
					lastList.splice(index,1);
				}
			}
			if(lastList.length>0&&lastList[0].indexOf("COM")>-1){
				Timer(evt.target).stop();
				currentPort = lastList[0];
				upgradeFirmware();
			}
			
			
		}
		public function upgradeFirmware():void{
			var file:File = File.applicationDirectory;
			var path:File = file.resolvePath("tools");
			var filePath:String = path.nativePath.split("\\").join("/")+"/";
			trace(path.nativePath+"\n");
			file = path.resolvePath("avrdude.exe");//外部程序名
			trace(file.nativePath+"\n");
			if(NativeProcess.isSupported) {
				
				var nativeProcessStartupInfo:NativeProcessStartupInfo =new NativeProcessStartupInfo();
				nativeProcessStartupInfo.executable = file;
				var v:Vector.<String> = new Vector.<String>();//外部应用程序需要的参数
				v.push("-C");
				v.push(filePath+"avrdude.conf")
				v.push("-v");
				v.push("-v");
				v.push("-v");
				v.push("-v");
				if(_board=="leonardo"){
					v.push("-patmega32u4");
					v.push("-cavr109");
					v.push("-P"+currentPort);
					v.push("-b57600");
					v.push("-D");
					v.push("-U");
					v.push("flash:w:"+filePath+"leonardo.hex:i");
				}else{
					v.push("-patmega328p");
					v.push("-carduino"); 
					v.push("-P"+currentPort);
					v.push("-b115200");
					v.push("-D");
					v.push("-V");
					v.push("-U");
					v.push("flash:w:"+filePath+"uno.hex:i");
				}
				nativeProcessStartupInfo.arguments = v;
				process = new NativeProcess();
				process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA,onStandardOutputData);
				process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
				process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
				process.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
				process.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError);
				process.start(nativeProcessStartupInfo);
			}else{
				trace("no support");
			}
			
			currentPort = "";
		}
		private function onStandardOutputData(event:ProgressEvent):void {
			LogManager.sharedManager().log(process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable ));
		}
		public function onErrorData(event:ProgressEvent):void
		{
			LogManager.sharedManager().log(process.standardError.readUTFBytes(process.standardError.bytesAvailable)); 
		}
		
		public function onExit(event:NativeProcessExitEvent):void
		{
			LogManager.sharedManager().log("Process exited with "+event.exitCode);
		}
		
		public function onIOError(event:IOErrorEvent):void
		{
			LogManager.sharedManager().log(event.toString());
		}
	}
}