package flashx.textLayout.edit.helpers
{
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.edit.IEditManager;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.elements.DivElement;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.ListElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.TextFlow;

	/**
	 * Utility class for creating lists of the currently selected elements in a FlowGroupElement.
	 */
	public class SelectionHelper
	{
		/**
		 * Returns true if the TextFlow's current selection state contains the supplied paragraph.
		 */
		public static function selectionContainsParagraph(tf:TextFlow, paragraph:ParagraphElement):Boolean
		{
			for each (var pe:ParagraphElement in getSelectedParagraphs(tf))
			{
				if (pe == paragraph)
				{
					return true;
				}
			}
			
			return false;
		}
		
		/**
		 * Returns true if any of the elements in the TextFlow's current selection state are of the supplied type.
		 */
		public static function selectionContainsElementType(tf:TextFlow, type:Class):Boolean
		{
			return getSelectedElements(tf, null, [type]).length > 0;
		}
		
		/**
		 * Returns true if there's at least one of the supplied types in the TextFlow's current selection state.
		 */
		public static function selectionContainsElementTypes(tf:TextFlow, types:Array):Boolean
		{
			return getSelectedElements(tf, null, types).length > 0;
		}
		
		/**
		 * Returns an Array containing all ParagraphElements that are at least 
		 * partially contained within the TextFlow's current selection state.
		 */
		public static function getSelectedParagraphs(tf:TextFlow, recurse:Boolean = true):Array 
		{
			return getSelectedElements(tf, null, [ParagraphElement], recurse);
		}
		
		/**
		 * Returns an Array containing all ListElements that are at least 
		 * partially contained within the TextFlow's current selection state.
		 */
		public static function getSelectedLists(tf:TextFlow):Array 
		{
			return getSelectedElements(tf, null, [ListElement]);
		}
		
		/**
		 * Returns an Array containing all the elements contained in the selection.
		 * If a SelectionState is not supplied then the FlowGroupElement must be a TextFlow object as the method will try 
		 * to use the TextFlow's interation manager to get a SelectionState to use.
		 * If an Array of Class definitions is supplied the list will only contain Classes of one of the supplied types.
		 *
		 * TODO: Make this method recursive: i.e. search through the children of the children etc. to find nested elements.
		 */		
		public static function getSelectedElements(tf:FlowGroupElement, selectionState:SelectionState = null, filter:Array = null, recurse:Boolean = true):Array 
		{
			var selectedElements:Array = [];
			
			// Make sure we have a selection state to work with.
			// Best not to fail silently or it could prove difficult to debug.
			if (selectionState == null)
			{
				if (tf is TextFlow)
				{
					selectionState = IEditManager(TextFlow(tf).interactionManager).getSelectionState();
				}
				else 
				{
					throw new Error("The supplied FlowGroupElement MUST be a TextFlow if you're not supplying a SelectionState");
				}
			}
			
			// Iterate over the children of the group.
			for (var i:int = 0; i < tf.numChildren; i++)
			{
				var element:FlowElement = tf.getChildAt(i);
				
				var canPush:Boolean = true;
				
				// If a filter set has been supplied make sure the element
				// matches at least one of the supplied types.
				if (filter)
				{
					var c:Class = getDefinitionByName(getQualifiedClassName(element)) as Class;
					var match:Boolean = false;
					for each (var clazz:Class in filter)
					{
						if (clazz == c)
						{
							match = true;
							break;
						}
					}
					
					canPush = match;
				}
				
				if (canPush)
				{										
					// If it's at least partially within the selection bounds then add it to the list.
					if ((element.getAbsoluteStart() + element.textLength) > selectionState.absoluteStart &&
						selectionState.absoluteEnd > element.getAbsoluteStart())
					{			
						selectedElements.push(element);
					}
					
				}
				if (element is FlowGroupElement && (recurse || selectedElements.length == 0))
				{
					selectedElements = selectedElements.concat(getSelectedElements(element as FlowGroupElement, selectionState, filter, recurse));
				}
			}
			
			return selectedElements;
		}
	}
}