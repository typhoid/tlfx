////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2008-2009 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
//////////////////////////////////////////////////////////////////////////////////
package flashx.textLayout.operations
{
	import flashx.textLayout.edit.ElementRange;
	import flashx.textLayout.edit.ParaEdit;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.SubParagraphGroupElement;
	import flashx.textLayout.formats.ITextLayoutFormat;
	import flashx.textLayout.formats.TextLayoutFormat;
	import flashx.textLayout.tlf_internal;

	use namespace tlf_internal;

	

	/**
	 * The InsertInlineGraphicOperation class encapsulates the insertion of an inline
	 * graphic into a text flow.
	 *
	 * @see flashx.textLayout.elements.InlineGraphicElement
	 * @see flashx.textLayout.edit.EditManager
	 * @see flashx.textLayout.events.FlowOperationEvent
	 * 
	 * @playerversion Flash 10
	 * @playerversion AIR 1.5
	 * @langversion 3.0 
	 */
	public class InsertInlineGraphicOperation extends FlowTextOperation
	{
		// Opening up as protected.
		protected var delSelOp:DeleteTextOperation; 
		protected var _source:Object;
		protected var imageWidth:Object;
		protected var imageHeight:Object;
		protected var _options:Object;
		protected var selPos:int = 0;
		
		/** 
		 * Creates an InsertInlineGraphicsOperation object.
		 * 
		 * @param operationState Describes the insertion point. 
		 * If a range is selected, the operation deletes the contents of that range.
		 * @param	source	The graphic source (uri string, URLRequest, DisplayObject, or Class of an embedded asset). 
		 * @param	width	The width to assign (number of pixels, percent, or the string 'auto')
		 * @param	height	The height to assign (number of pixels, percent, or the string 'auto')
		 * @param	options	None supported
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0 
		 */
		function InsertInlineGraphicOperation(operationState:SelectionState, source:Object, width:Object, height:Object, options:Object = null)
		{
			super(operationState);
			
			if (absoluteStart != absoluteEnd)
				delSelOp = new DeleteTextOperation(operationState);
				
			_source = source;
			_options = options;
			imageWidth = width;
			imageHeight = height;
		}
		
		/**	
		 * @copy flashx.textLayout.elements.InlineGraphicElement#source
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0 
 		 */
		public function get source():Object
		{
			return _source;
		}
		public function set source(value:Object):void
		{
			_source = value;
		}

		/** 
		 * @copy flashx.textLayout.elements.InlineGraphicElement#width
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0 
		 */
		public function get width():Object
		{
			return imageWidth;
		}
		public function set width(value:Object):void
		{
			imageWidth = value;
		}

		/** 
		 * @copy flashx.textLayout.elements.InlineGraphicElement#height
		 * 
		 * @see flashx.textLayout.InlineGraphicElement#height
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0 
		*/
		public function get height():Object
		{
			return imageHeight;
		}
		public function set height(value:Object):void
		{
			imageHeight = value;
		}
		
		/** 
		 * options are not supported
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0 
		*/
		public function get options():Object
		{
			return _options;
		}
		public function set options(value:Object):void
		{
			_options = value;
		}

		/** @private */
		public override function doOperation():Boolean
		{
			var pointFormat:ITextLayoutFormat;
			
			selPos = absoluteStart;
			if (delSelOp) 
			{
				var leafEl:FlowLeafElement = textFlow.findLeaf(absoluteStart);
				var deleteFormat:ITextLayoutFormat = new TextLayoutFormat(textFlow.findLeaf(absoluteStart).format);
				if (delSelOp.doOperation())
					pointFormat = deleteFormat;
			}
			else
				pointFormat = originalSelectionState.pointFormat;
				
			// lean left logic included
			var range:ElementRange = ElementRange.createElementRange(textFlow,selPos, selPos);		
			var leafNode:FlowElement = range.firstLeaf;
			var leafNodeParent:FlowGroupElement = leafNode.parent;
			while (leafNodeParent is SubParagraphGroupElement)
			{
				var subParInsertionPoint:int = selPos - leafNodeParent.getAbsoluteStart();
				if (((subParInsertionPoint == 0) && (!(leafNodeParent as SubParagraphGroupElement).acceptTextBefore())) ||
					((subParInsertionPoint == leafNodeParent.textLength) && (!(leafNodeParent as SubParagraphGroupElement).acceptTextAfter())))
				{
					leafNodeParent = leafNodeParent.parent;
				} else {
					break;
				}
			}
			
			ParaEdit.createImage(leafNodeParent, selPos - leafNodeParent.getAbsoluteStart(), _source, imageWidth, imageHeight, options, pointFormat);
			if (textFlow.interactionManager)
				textFlow.interactionManager.notifyInsertOrDelete(absoluteStart, 1);
			
			return true;
		}
	
		/** @private */
		public override function undo():SelectionState
		{
			var leafNode:FlowElement = textFlow.findLeaf(selPos);
			var leafNodeParent:FlowGroupElement = leafNode.parent;
			var elementIdx:int = leafNode.parent.getChildIndex(leafNode);
			leafNodeParent.replaceChildren(elementIdx, elementIdx + 1, null);			
					
			if (textFlow.interactionManager)
				textFlow.interactionManager.notifyInsertOrDelete(absoluteStart, -1);

			return delSelOp ? delSelOp.undo() : originalSelectionState; 
		}

		/**
		 * Re-executes the operation after it has been undone.
		 * 
		 * <p>This function is called by the edit manager, when necessary.</p>
		 * 
		 * @playerversion Flash 10
		 * @playerversion AIR 1.5
	 	 * @langversion 3.0 
		 */
		public override function redo():SelectionState
		{ 
			doOperation();
			return new SelectionState(textFlow,selPos+1,selPos+1,null);
		}
		
		// [TA] 07-27-2010 :: See comment on FlowOperation.
		override public function get affectsFlowStructure():Boolean
		{
			return true;
		}
		// [END TA]
	}
}
