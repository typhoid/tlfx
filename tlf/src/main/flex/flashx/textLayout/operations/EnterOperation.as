package flashx.textLayout.operations
{
	import flash.events.KeyboardEvent;
	import flash.utils.getQualifiedClassName;
	
	import flashx.textLayout.container.AutosizableContainerController;
	import flashx.textLayout.container.ContainerController;
	import flashx.textLayout.converter.IHTMLExporter;
	import flashx.textLayout.converter.IHTMLImporter;
	import flashx.textLayout.edit.EditManager;
	import flashx.textLayout.edit.ExtendedEditManager;
	import flashx.textLayout.edit.ParaEdit;
	import flashx.textLayout.edit.SelectionState;
	import flashx.textLayout.edit.helpers.SelectionHelper;
	import flashx.textLayout.elements.FlowElement;
	import flashx.textLayout.elements.FlowGroupElement;
	import flashx.textLayout.elements.FlowLeafElement;
	import flashx.textLayout.elements.ParagraphElement;
	import flashx.textLayout.elements.SpanElement;
	import flashx.textLayout.elements.TextFlow;
	import flashx.textLayout.elements.list.ListElementX;
	import flashx.textLayout.elements.list.ListItemElementX;
	import flashx.textLayout.elements.list.ListPaddingElement;
	import flashx.textLayout.tlf_internal;
	import flashx.textLayout.utils.ListUtil;
	
	use namespace tlf_internal;
	
	/**
	 * The TabOperation is a subclass that tabs text.
	 * 
	 * @author dominickaccattato
	 * 
	 */
	public class EnterOperation extends FlowTextOperation
	{
		private var interactionManager:ExtendedEditManager;
				
		protected var _htmlImporter:IHTMLImporter;
		protected var _htmlExporter:IHTMLExporter;
								
		/**
		 * 
		 * @param operationState
		 * @param interactionManager
		 * @param importer
		 * @param exporter
		 * 
		 */
		public function EnterOperation( operationState:SelectionState, interactionManager:ExtendedEditManager, importer:IHTMLImporter, exporter:IHTMLExporter )
		{
			super( operationState );
			
			// Set the interaction manager so that we can reference it while deleting lists.
			this.interactionManager = interactionManager;
			_htmlImporter = importer;
			_htmlExporter = exporter;
		}
				
		/**
		 * doOperation is called by ExtendedEditManager.
		 * 
		 * @return 
		 * 
		 */
		public override function doOperation():Boolean	{
			var operationState:SelectionState = interactionManager.getSelectionState();
			
			if(isCaretSelection()) {
				var leaf:FlowLeafElement = textFlow.findLeaf(operationState.absoluteStart-1);
				//operationState.pointFormat = leaf.format;
				interactionManager.splitParagraph(operationState);
				interactionManager.refreshSelection();
			} else {
				
				if( !operationState ) {
					return true;
				}
				
				leaf = textFlow.findLeaf(operationState.absoluteStart);
				//operationState.pointFormat = leaf.format;
				
				// do the specific operation passing in the listMode argument
				interactionManager.doOperation( new BackspaceOperation( operationState, interactionManager ) );
				
				// get previous leaf format
				interactionManager.splitParagraph(operationState);
				
				/// apply it
				interactionManager.refreshSelection();
				
			}
			
			var nextLeaf:ListItemElementX = textFlow.findLeaf(absoluteEnd+1).parent as ListItemElementX;
			var prevLeaf:ListItemElementX = textFlow.findLeaf(absoluteEnd).parent as ListItemElementX;
			if(prevLeaf) {
				// get the parent
				// if the previous leaf has a modified text length of 0 we then have to check to see if the next
				// leaf does not have a modifiedtextlength of 0. If the next leaf has a modified text length
				// greater than 0 then we know we are moving the item down.  Without this logic, the list will close.o
				var list:ListElementX = prevLeaf.parent as ListElementX;
				if(prevLeaf.modifiedTextLength == 0 && nextLeaf.modifiedTextLength == 0 && list.listItems[list.listItems.length-1] == nextLeaf) {
					closeList(nextLeaf);
					return true;
				}
				
				if(nextLeaf) {
					var parentList:ListElementX = nextLeaf.parent as ListElementX;
					if( parentList ) parentList.update();
					
					var ss:SelectionState = new SelectionState(textFlow, nextLeaf.actualStart-1, nextLeaf.actualStart-1);
					interactionManager.setSelectionState(ss);
					interactionManager.refreshSelection();
				}
			} 
			
			return true;	
		}
		
		private function closeList(leaf:ListItemElementX) : void {

			var item:ListItemElementX = leaf.parent as ListItemElementX;
			
			var list:ListElementX = leaf.parent as ListElementX;

			list.removeChild(leaf);
			list.removeChild(list.listItems.pop()); // use the same index since they shift
			list.update();
			
			// we want to move to the next sibling of the list. however if we are in a blank editor
			// and the user has removed the next sibling by deleting it we will need to create a new paragraph element.
			var nextSibling:FlowElement = list.getNextSibling();
			
			if(!nextSibling) {
				var containerController:AutosizableContainerController;
				var newPara:ParagraphElement = new ParagraphElement();
				var newSpan:SpanElement = new SpanElement();
				newSpan.text = "";
				newPara.addChild(newSpan);
				containerController = ListUtil.findContainerControllerForElement(list);
				//newPara.format = leaf.computedFormat;
				nextSibling = textFlow.addChildAt(textFlow.getChildIndex(list)+1, newPara);
				containerController.addMonitoredElement(newPara);
				//textFlow.flowComposer.updateAllControllers();
				
			}
						
			// get the selection state
			var operationState:SelectionState = interactionManager.getSelectionState();
			operationState.anchorPosition = nextSibling.getAbsoluteStart();
			operationState.activePosition = nextSibling.getAbsoluteStart();
			
			// set the selection state
			interactionManager.setSelectionState(operationState);
			interactionManager.refreshSelection();
			
			textFlow.flowComposer.updateAllControllers();
		}
		
		/**
		 * 
		 * @return 
		 * 
		 */
		public override function undo():SelectionState
		{
			/*
			if( _listModeChange )
			{
			undoListModeChange();
			}
			else if( _listModeCreateOnTextFlow )
			{
			removeListFromTextFlow( _listCreatedOnTextFlow );
			}*/
			return originalSelectionState; 
		}
		
		/**
		 * Helper function that returns whether there is a selection being deleted
		 * or just a caret delete. If absoluteStart is equal to absoluteEnd we can assume that there is no selection and
		 * we should delete according to the following rules. 
		 * 
		 * @return 
		 * 
		 */
		private function isCaretSelection() : Boolean {
			return (absoluteStart == absoluteEnd);
		}
		
	}
}