package com
{
	import flash.events.Event;

	public class PlayListEvent extends Event
	{
		
		public static const SELECT_ITEM : String = "select_item";
		private var _itemID : Number;
		
		public function get itemID() : Number
		{
			return _itemID;
		}
		
		public function PlayListEvent(id : Number)
		{
			_itemID = id;
			super(PlayListEvent.SELECT_ITEM);
		}
		
		
		
	}
}