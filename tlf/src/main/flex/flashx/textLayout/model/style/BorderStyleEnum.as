package flashx.textLayout.model.style
{
	/**
	 * TableBorderEnum is an enumeration of the border style values related to CSS of table. 
	 * @author toddanderson
	 */
	public class BorderStyleEnum
	{
		public static const OUTSET:String = "outset";
		public static const INSET:String = "inset";
		public static const NONE:String = "none";
		public static const HIDDEN:String = "hidden";
		public static const DOTTED:String = "dotted";
		public static const DASHED:String = "dashed";
		public static const SOLID:String = "solid";
		public static const DOUBLE:String = "double";
		public static const RIDGE:String = "ridge";
		public static const GROOVE:String = "groove";
		public static const UNDEFINED:String = "undefined";
		
		public static function getList():Array
		{
			return [BorderStyleEnum.OUTSET, BorderStyleEnum.INSET, BorderStyleEnum.NONE,
							BorderStyleEnum.HIDDEN, BorderStyleEnum.DOTTED, BorderStyleEnum.DASHED,
							BorderStyleEnum.SOLID, BorderStyleEnum.DOUBLE, BorderStyleEnum.RIDGE,
							BorderStyleEnum.GROOVE];
		}
	}
}