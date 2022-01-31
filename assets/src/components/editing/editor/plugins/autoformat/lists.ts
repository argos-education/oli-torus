import {
  TEditor,
  getParent,
  isElement,
  isType,
  PlateEditor,
  toggleList,
  AutoformatRule,
  ELEMENT_LI,
  ELEMENT_UL,
  ELEMENT_OL,
  ELEMENT_TODO_LI,
} from '@udecode/plate';
import { clearBlockFormat } from 'components/editing/editor/plugins/autoformat/utils';

export const format = (editor: TEditor, customFormatting: any) => {
  if (editor.selection) {
    const parentEntry = getParent(editor, editor.selection);
    if (!parentEntry) return;
    const [node] = parentEntry;
    if (isElement(node) && !isType(editor as PlateEditor, node, 'code')) {
      customFormatting();
    }
  }
};

export const formatList = (editor: TEditor, elementType: string) => {
  format(editor, () =>
    toggleList(editor as PlateEditor, {
      type: elementType,
    }),
  );
};

export const autoformatLists: AutoformatRule[] = [
  {
    mode: 'block',
    type: ELEMENT_LI,
    match: ['* ', '- '],
    preFormat: clearBlockFormat,
    format: (editor) => formatList(editor, ELEMENT_UL),
  },
  {
    mode: 'block',
    type: ELEMENT_LI,
    match: ['1. ', '1) '],
    preFormat: clearBlockFormat,
    format: (editor) => formatList(editor, ELEMENT_OL),
  },
  {
    mode: 'block',
    type: ELEMENT_TODO_LI,
    match: '[] ',
  },
  // {
  //   mode: 'block',
  //   type: ELEMENT_TODO_LI,
  //   match: '[x] ',
  //   format: (editor) =>
  //     setNodes<TElement<TodoListItemNodeData>>(
  //       editor,
  //       { type: ELEMENT_TODO_LI, checked: true },
  //       {
  //         match: (n) => Editor.isBlock(editor, n),
  //       },
  //     ),
  // },
];
