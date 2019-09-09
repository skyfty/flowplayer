/***********************************************************
 * 
 * Copyright 2011 Adobe Systems Incorporated. All Rights Reserved.
 *
 * *********************************************************
 * The contents of this file are subject to the Berkeley Software Distribution (BSD) Licence
 * (the "License"); you may not use this file except in
 * compliance with the License. 
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations
 * under the License.
 *
 *
 * The Initial Developer of the Original Code is Adobe Systems Incorporated.
 * Portions created by Adobe Systems Incorporated are Copyright (C) 2011 Adobe Systems
 * Incorporated. All Rights Reserved.
 **********************************************************/
package org.osmf.smpte.tt.model
{
	import flashx.textLayout.conversion.FormatDescriptor;
	
	import org.osmf.smpte.tt.formatting.Animation;
	import org.osmf.smpte.tt.formatting.Block;
	import org.osmf.smpte.tt.formatting.FormattingObject;
	import org.osmf.smpte.tt.formatting.Paragraph;
	import org.osmf.smpte.tt.model.metadata.MetadataElement;
	import org.osmf.smpte.tt.timing.TimeCode;
	import org.osmf.smpte.tt.timing.TimeContainer;
	import org.osmf.smpte.tt.timing.TimeTree;
	import org.osmf.smpte.tt.utilities.DictionaryUtils;
	
	public class PElement extends TimedTextElementBase
	{
		public function PElement()
		{
			timeSemantics = TimeContainer.PAR
		}
		
		////{ region Formatting
		/**
		 * Return formatting object for p element
		 * @param regionId
		 * @param tick
		 */
		public override function getFormattingObject(tick:TimeCode):FormattingObject
		{
			
			if (temporallyActive(tick))
			{
				
				var block:Paragraph = new Paragraph(this);
				var fo:FormattingObject;
				for each (var child:* in children)
				{
					if (child is BrElement || child is AnonymousSpanElement)
					{
						fo = (child as TimedTextElementBase).getFormattingObject(tick);
						if (fo != null)
						{
							fo.parent = block;
							block.children.push(fo);
							for(var d:* in metadata)
							{
								if (!org.osmf.smpte.tt.utilities.DictionaryUtils.containsKey(child.metadata,d))
								{
									child.metadata[d] = metadata[d];
								}
							}
						}
					}
					else if (child is SpanElement)
					{
						fo = (child as SpanElement).getFormattingObject(tick);
						if (fo != null)
						{
							/// Flattened nested <span>A<span>B</span>C</span>
							/// -> <Inline>A</Inline><Inline>B</Inline><Inline>C</Inline>
							/// by hoisting out to outer context.
							/// nested elements will still inherit correctly, as style is inherited 
							/// throughthe tt_element tree, not the formatting object tree.
							/// something to watch out for when computing relative values though.
							for each (var nestedInline:* in fo.children)
							{
								nestedInline.parent = block;
								block.children.push(nestedInline);
								// copy the childs animations into the grandchild
								// - need to watch the order here.
								// deepest animations should win, so they need to be last in the list. 
								// we reverse the list on entry so they get inserted at the front in
								// the right order.
								fo.animations.reverse(); // these are getting discarded.
								for each (var animation:Animation in fo.animations)
								{
									var grandchild:FormattingObject = nestedInline as FormattingObject;
									grandchild.animations.unshift(animation);
								}
							}
							
						}
					}
					if (child is SetElement)
					{
						fo = ((child as SetElement).getFormattingObject(tick)) as Animation;
						if (fo != null)
						{
							block.animations.push(fo);
						}
					}
				}
				return block;
			}
			else
			{
				return null;
			}
		}
		//} endregion
		
		//{ region Validity
		/*
		<p
		begin = <timeExpression>
		dur = <timeExpression>
		end = <timeExpression>
		region = IDREF
		style = IDREFS
		timeContainer = (par|seq)
		xml:id = ID
		xml:lang = string
		xml:space = (default|preserve)
		{any attribute in TT Metadata namespace ...}
		{any attribute in TT Style namespace ...}
		{any attribute not in default or any TT namespace ...}>
		Content: Metadata.class*, Animation.class*, Inline.class*
		</p>
		*/
		/**
		 * Check validity of p element attributes
		 */
		protected override function validAttributes():void
		{
			validateAttributes(false, true, true, true, true, true);
		}
		
		/**
		 * Check validity of p element content model
		 */
		protected override function validElements():void
		{
			var child:uint = 0;
			
			//{ region Allow arbitrary metadata
			while ((child < children.length)
				&& ((children[child] is org.osmf.smpte.tt.model.MetadataElement)
					|| (children[child] is org.osmf.smpte.tt.model.metadata.MetadataElement)
					//      || (children[child] is anonymousSpan)
				))
			{
				child++;
			}
			//} endregion
			
			//{ region Allow arbitrary set elements (Animation class)
			while ((child < children.length)
				&& ((children[child] is SetElement)
					//|| (children[child] is anonymousSpan)
				))
			{
				child++;
			}
			//} endregion
			
			//{ region Allow arbitrary span, br, PCDATA (Inline class)
			while ((child < children.length)
				&& ((children[child] is SpanElement)
					|| (children[child] is BrElement)
					|| (children[child] is AnonymousSpanElement)
				))
			{
				child++;
			}
			//} endregion
			
			//{ region Check no other element is present
			if (children.length != child)
			{
				error(children[child] + " is not allowed in " + this + " at position " + child);
			}
			//} endregion
			
			//{ region now check each of the children is individually valid
			for each (var element:TimedTextElementBase in children)
			{
				element.valid();
			}
			//} endregion
				
		}
		//} endregion		
	}
}