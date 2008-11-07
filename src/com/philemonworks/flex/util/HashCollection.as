/*
   Copyright [2007] Ernest.Micklei @ PhilemonWorks.com

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
package com.philemonworks.flex.util
{
	import mx.collections.ArrayCollection;

	/**
	 * HashCollection implements a Hash in which the values are Bindable.
	 * This means that other objects can be notified when a value changes.
	 * 
	 * @author Ernest.Micklei, 2007
	 */
	public class HashCollection extends ArrayCollection
	{
		public function HashCollection(source:Array=null)
		{
			super(source);
		}
		private var _keyToIndexHash:Object = new Object();
		
		[Bindable("collectionChange")]
		public function put(key:Object,value:Object):void {
			var indexOrNull:* = _keyToIndexHash[key]
			if (indexOrNull == undefined) {
				var index:int = this.length
				this.addItem(value)
				_keyToIndexHash[key]=index
				this.setItemAt(value,index)
			} else {
				this.setItemAt(value,indexOrNull as int)
			}
		}			
		[Bindable("collectionChange")]
		public function get(key:Object):Object {
			var indexOrNull:* = _keyToIndexHash[key]
			if (indexOrNull == undefined) {
				// no value for key so we return null
				return null
			}
			var index:int = indexOrNull as int
			return super.getItemAt(index)
		}
		/**
		 * Convenience method to access a String value
		 */
		[Bindable("collectionChange")]
		public function getString(key:String):String {
			var value:Object = this.get(key)
			return value == null ? null : value as String
		}
	}
}