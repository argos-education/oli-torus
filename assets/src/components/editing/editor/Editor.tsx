import { withHtml } from 'components/editing/editor/overrides/html';
import { Model } from 'data/content/model/elements/factories';
import { Mark, Marks } from 'data/content/model/text';
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { createEditor, Descendant, Editor as SlateEditor, Operation, Transforms } from 'slate';
import { withHistory } from 'slate-history';
import { withReact } from 'slate-react';
import { classNames } from 'utils/classNames';
import { CommandContext, CommandDescription } from '../elements/commands/interfaces';
import { hotkeyHandler } from './handlers/hotkey';
import { onKeyDown as listOnKeyDown } from './handlers/lists';
import { onKeyDown as quoteOnKeyDown } from './handlers/quote';
import { onKeyDown as titleOnKeyDown } from './handlers/title';
import { onKeyDown as voidOnKeyDown } from './handlers/void';
import { editorFor, markFor } from './modelEditorDispatch';
import { installNormalizer, NormalizerContext } from './normalizers/normalizer';
import { withInlines } from './overrides/inlines';
import { withMarkdown } from './overrides/markdown';
import { withTables } from './overrides/tables';
import {
  Plate,
  withPlate,
  TNode,
  usePlateStore,
  usePlateEditorState,
  getText,
  ELEMENT_IMAGE,
} from '@udecode/plate';
import { plugins } from 'components/editing/editor/plugins/plugins';
import { EditorToolbar } from 'components/editing/toolbar/EditorToolbar';
import { toSimpleText } from 'components/editing/utils';

const normalized = (values: TNode[]) => {
  const editor = usePlateEditorState();
  console.log('values before', values);

  return values.map((node) => {
    if (!Element.isElement(node)) return node;
    console.log(node.type);
    switch (node.type) {
      case 'code':
        const text = toSimpleText(node);
        console.log('text', text);
        return node;
      case 'img':
        console.log('img, normalizing', node);
        console.log('to return', {
          ...node,
          url: node.src || node.url,
          children: [{ text: '' }],
          caption:
            typeof node.caption === 'string'
              ? [{ children: [{ text: node.caption ?? '' }] }]
              : node.caption,
        });
        // if (node.url) return node;
        return {
          type: 'img',
          children: node.children,
          element: {
            url: node.src || node.url,
            caption:
              typeof node.caption === 'string'
                ? [{ children: [{ text: node.caption ?? '' }] }]
                : node.caption,
          },
        };

      default:
        return node;
    }
  });
};

export type EditorProps = {
  // Callback when there has been any change to the editor
  onEdit: (children: TNode[]) => void;
  // The content to display
  value: TNode[];
  // The insertion toolbar configuration
  toolbarInsertDescs: CommandDescription[];
  // Whether or not editing is allowed
  editMode: boolean;
  commandContext: CommandContext;
  normalizerContext?: NormalizerContext;
  className?: string;
  style?: React.CSSProperties;
  placeholder?: string;
  children?: React.ReactNode;
  id: string;
};

// Necessary to work around FireFox focus and selection issues with Slate
// https://github.com/ianstormtaylor/slate/issues/1984
function emptyOnFocus() {
  return;
}

function areEqual(prevProps: EditorProps, nextProps: EditorProps) {
  return (
    prevProps.editMode === nextProps.editMode &&
    prevProps.toolbarInsertDescs === nextProps.toolbarInsertDescs &&
    prevProps.value === nextProps.value &&
    prevProps.placeholder === nextProps.placeholder &&
    prevProps.children === nextProps.children
  );
}

export const Editor: React.FC<EditorProps> = (props: EditorProps) => {
  const editor = useMemo(
    () => withReact(withHistory(withTables(createEditor()))),
    [props.commandContext],
  );

  const store = usePlateStore(props.id);
  useEffect(() => {
    const value = store.get.value();
    if (value) props.onEdit(value);
  }, [store.get.value()]);

  return (
    <Plate
      id={props.id}
      plugins={plugins}
      normalizeInitialValue
      editor={withPlate(editor, { id: props.id, plugins })}
      value={props.value.length === 0 ? [Model.p()] : normalized(props.value)}
      // normalizeInitialValue -> Use this to migrate to newer versions (eg codeblock)
      // Can put overrides as plugins instead of changing editor prop: see https://plate.udecode.io/docs/plugins#with-overrides
      editableProps={{
        style: props.style,
        readOnly: !props.editMode,
        className: classNames(['slate-editor', 'overflow-auto', props.className]),
        placeholder: props.placeholder ?? 'Enter some content here...',
        onPaste: (e) => {
          const pastedText = e.clipboardData?.getData('text')?.trim();
          const youtubeRegex =
            /^(?:(?:https?:)?\/\/)?(?:(?:www|m)\.)?(?:(?:youtube\.com|youtu.be))(?:\/(?:[\w-]+\?v=|embed\/|v\/)?)([\w-]+)(?:\S+)?$/;
          const matches = pastedText.match(youtubeRegex);
          if (matches != null) {
            // matches[0] === the entire url
            // matches[1] === video id
            const [, videoId] = matches;
            e.preventDefault();
            Transforms.insertNodes(editor, [Model.youtube(videoId)]);
          }
        },
      }}
    >
      {props.children}
      {/* <NewEditorToolbar /> */}
      <EditorToolbar context={props.commandContext} toolbarInsertDescs={props.toolbarInsertDescs} />
    </Plate>
  );
};
Editor.displayName = 'Editor';

// const onKeyDown = useCallback((e: React.KeyboardEvent) => {
//   voidOnKeyDown(editor, e);
//   listOnKeyDown(editor, e);
//   quoteOnKeyDown(editor, e);
//   titleOnKeyDown(editor, e);
//   hotkeyHandler(editor, e.nativeEvent, props.commandContext);
// }, []);

// const decorate = useCallback(
//   ([node, path]: NodeEntry<Node>): BaseRange[] => {
//     // placeholder decoration
//     if (
//       editor.selection &&
//       !SlateEditor.isEditor(node) &&
//       SlateEditor.string(editor, [path[0]]) === '' &&
//       Range.includes(editor.selection, path) &&
//       Range.isCollapsed(editor.selection)
//     )
//       return [{ ...editor.selection, placeholder: true } as BaseRange];

//     return [];
//   },
//   [editor],
// );

// const renderLeaf = useCallback(({ attributes, children, leaf }: RenderLeafProps) => {
//   const markup = Object.keys(leaf).reduce(
//     (m, k) => (k in Marks ? markFor(k as Mark, m) : m),
//     children,
//   );
//   return (
//     <span {...attributes} style={leaf.placeholder && { position: 'relative' }}>
//       {markup}
//       {leaf.youtubeInput && <span>Enter something</span>}
//       {leaf.placeholder && (
//         <span
//           style={{
//             opacity: 0.3,
//             position: 'absolute',
//             top: 0,
//             width: 'max-content',
//             lineHeight: '18px',
//           }}
//           contentEditable={false}
//         >
//           Start typing or press &apos;/&apos; to insert content
//         </span>
//       )}
//     </span>
//   );
// }, []);
