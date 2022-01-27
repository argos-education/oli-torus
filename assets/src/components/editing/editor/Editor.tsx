import { withHtml } from 'components/editing/editor/overrides/html';
import { Model } from 'data/content/model/nodes/factories';
import { Mark, Marks } from 'data/content/model/text';
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  BaseRange,
  createEditor,
  Editor as SlateEditor,
  Element,
  Node,
  NodeEntry,
  Operation,
  Path,
  Range,
  Transforms,
} from 'slate';
import { withHistory } from 'slate-history';
import { Editable, RenderElementProps, RenderLeafProps, Slate, withReact } from 'slate-react';
import { classNames } from 'utils/classNames';
import { CommandContext, CommandDesc, ToolbarItem } from '../nodes/commands/interfaces';
import { hotkeyHandler } from './handlers/hotkey';
import { onKeyDown as listOnKeyDown } from '../../../data/content/model/nodes/list/lists';
import { onKeyDown as quoteOnKeyDown } from './handlers/quote';
import { onKeyDown as titleOnKeyDown } from './handlers/title';
import { onKeyDown as voidOnKeyDown } from './handlers/void';
import { editorFor, markFor } from './modelEditorDispatch';
import { installNormalizer, NormalizerContext } from './normalizers/normalizer';
import { withInlines } from './overrides/inlines';
import { withMarkdown } from './overrides/markdown';
import { withTables } from './overrides/tables';
import { withVoids } from './overrides/voids';
import { EditorToolbar } from 'components/editing/toolbar/EditorToolbar';
import { ActivityEditContext } from 'data/content/activity';
import { ResourceContent } from 'data/content/resource';
import {
  addColumn,
  addRow,
  AlignToolbarButton,
  BlockToolbarButton,
  CodeBlockToolbarButton,
  createBlockquotePlugin,
  createBoldPlugin,
  createCodeBlockPlugin,
  createCodePlugin,
  createHeadingPlugin,
  createImagePlugin,
  createItalicPlugin,
  createLinkPlugin,
  createParagraphPlugin,
  createPlateUI,
  createPlugins,
  createStrikethroughPlugin,
  createTablePlugin,
  createUnderlinePlugin,
  deleteColumn,
  deleteRow,
  deleteTable,
  getPluginType,
  getPreventDefaultHandler,
  HeadingToolbar,
  indent,
  insertTable,
  ListToolbarButton,
  MarkToolbarButton,
  MARK_BOLD,
  MARK_CODE,
  MARK_ITALIC,
  MARK_STRIKETHROUGH,
  MARK_SUBSCRIPT,
  MARK_SUPERSCRIPT,
  MARK_UNDERLINE,
  outdent,
  Plate,
  TableToolbarButton,
  ToolbarButton,
  usePlateEditorRef,
  createIndentListPlugin,
  withPlate,
  ELEMENT_H1,
  ELEMENT_H2,
  ELEMENT_BLOCKQUOTE,
  TNode,
  usePlate,
  usePlateEditorState,
  pipeOnChange,
  usePlateStore,
  ELEMENT_LIC,
  ELEMENT_UL,
  ELEMENT_OL,
  createListPlugin,
  createIndentPlugin,
  ELEMENT_PARAGRAPH,
  toggleIndentList,
  withProps,
  StyledElement,
  getListItemEntry,
  ELEMENT_LI,
  getAbove,
  getNode,
  getParent,
  isCollapsed,
  TElement,
  createAlignPlugin,
  createNormalizeTypesPlugin,
  getNodes,
  createPluginFactory,
  WithOverride,
  ErrorHandler,
  setNodes,
  setIndent,
} from '@udecode/plate';
import { LooksOne } from '@styled-icons/material/LooksOne';
import { LooksTwo } from '@styled-icons/material/LooksTwo';
import { FormatQuote } from '@styled-icons/material/FormatQuote';
import { CodeBlock } from '@styled-icons/boxicons-regular/CodeBlock';
import {
  BorderAll,
  BorderBottom,
  BorderClear,
  BorderLeft,
  BorderRight,
  BorderTop,
  FormatAlignCenter,
  FormatAlignJustify,
  FormatAlignLeft,
  FormatAlignRight,
  FormatBold,
  FormatIndentDecrease,
  FormatIndentIncrease,
  FormatItalic,
  FormatListBulleted,
  FormatListNumbered,
  FormatStrikethrough,
  FormatUnderlined,
  Subscript,
  Superscript,
} from 'styled-icons/material';
import { CodeAlt } from 'styled-icons/boxicons-regular';
import guid from 'utils/guid';
import path from 'path';
import { node } from 'webpack';

export type EditorProps = {
  // Callback when there has been any change to the editor
  onEdit: (children: TNode[]) => void;
  // The content to display
  value: TNode[];
  // The insertion toolbar configuration
  toolbarInsertDescs: CommandDesc[];
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

const migrateModel: WithOverride<
  Record<string, never>,
  { rules: { match: any; migrate: any }[] }
> = (editor, { options: { rules } }) => {
  const { normalizeNode } = editor;

  editor.normalizeNode = ([currentNode, currentPath]) => {
    const endCurrentNormalizationPath = rules.some(({ match, migrate }) => {
      if (!match(currentNode, currentPath)) return false;
      migrate(currentNode, currentPath);
      return true;
    });
    if (endCurrentNormalizationPath) return;

    return normalizeNode([currentNode, currentPath]);
  };

  return editor;
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

export const Editor: React.FC<EditorProps> = React.memo((props: EditorProps) => {
  // const [installed, setInstalled] = useState(false);

  const editor = useMemo(
    // need markdown, html
    () => withReact(withHistory(withTables(createEditor()))),
    [props.commandContext],
  );
  // const [id] = React.useState(guid());
  const plateEditor = usePlateEditorState(props.id);
  const store = usePlateStore(props.id);
  useEffect(() => {
    const value = store.get.value();
    if (value) props.onEdit(value);
  }, [store.get.value()]);

  // Install the custom normalizer, only once
  // useEffect(() => {
  //   if (!installed) {
  //     installNormalizer(editor, props.normalizerContext);
  //     setInstalled(true);
  //   }
  // }, [installed]);

  // const renderElement = useCallback(
  //   (renderProps: RenderElementProps) =>
  //     editorFor(renderProps.element, renderProps, props.commandContext),
  //   [props.commandContext, editor],
  // );

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
  // const [value, setValue] = useState(props.value.length === 0 ? [Model.p()] : props.value);

  // const onChange = React.useCallback(
  //   (value: TNode[]) => {
  //     const { operations } = plateEditor;

  //     // Determine if this onChange was due to an actual content change.
  //     // Otherwise, undo/redo will save pure selection changes.
  //     if (operations.filter(({ type }) => type !== 'set_selection').length) {
  //       props.onEdit(value);
  //     }
  //     setValue(value);
  //   },
  //   [plateEditor, props.onEdit],
  // );

  const plugins = createPlugins(
    [
      // Blocks
      createHeadingPlugin({
        options: {},
      }),
      createParagraphPlugin({}),
      createBlockquotePlugin(),
      createCodeBlockPlugin(),
      createTablePlugin(),
      createImagePlugin(),

      createIndentListPlugin(),
      createIndentPlugin({
        inject: {
          props: {
            validTypes: [ELEMENT_PARAGRAPH, ELEMENT_H2],
          },
        },
      }),
      createAlignPlugin(),

      // Inlines
      createLinkPlugin(),

      // Marks
      createBoldPlugin(),
      createItalicPlugin(),
      createUnderlinePlugin(),
      createStrikethroughPlugin(),
      createCodePlugin(),

      // Normalizers
      createNormalizeTypesPlugin({
        rules: [{ path: getNodes(editor), strictType: ELEMENT_H1 }],
      } as any),

      createPluginFactory<{
        rules: { match: (n: Node, p: Path) => boolean; migrate: (n: Node, p: Path) => void }[];
      }>({
        key: 'migrateModel',
        withOverrides: migrateModel,
        options: {
          rules: [
            {
              // TODO: unwrap ol/ul, AFTER this (so indent stays).
              // TODO: Change table editor to use most of the plate editor but with caption support
              match: (node) => Element.isElement(node) && node.type === 'li',
              migrate: (node, path) => {
                const parent = getAbove(plateEditor, {
                  match: (e) => Element.isElement(e) && (e.type === 'ol' || e.type === 'ul'),
                });
                const indentLevel = [
                  ...getNodes(plateEditor, {
                    match: (e) => Element.isElement(e) && (e.type === 'ul' || e.type === 'ol'),
                  }),
                ].length;
                toggleIndentList(plateEditor, {
                  listStyleType: parent?.[0].type === 'ol' ? 'disc' : 'decimal',
                  offset: indentLevel,
                  getNodesOptions: { at: path },
                });
              },
            },
            // is the type of node we're looking for
            // xordered list
            // xunordered list
            // xli
            // xtable
            // xtable row
            //  xtable header
            //  xtable data
            // xmath ?? (not in use?)
            //  xmath line
            // code
            //  code line
            // blockquote
            // hyperlink
            // input ref
            // popup
            // marks
            // what to do with voids - continue using current editors?
            // image
            // youtube
            // audio
            // webpage / iframe
          ],
        },
      })(),
    ],
    {
      components: {
        ...createPlateUI(),
        [ELEMENT_PARAGRAPH]: withProps(StyledElement, {
          as: 'div',
          styles: {
            root: {
              margin: 0,
              padding: '4px 0',
            },
          },
        }),
      },
    },
  );

  return (
    <Plate
      id={props.id}
      plugins={plugins}
      normalizeInitialValue
      // onChange={onChange}
      // onChange={(value) => console.log('new value', value) || props.onEdit(value)}
      editor={withPlate(editor, { id: props.id, plugins })}
      value={props.value.length === 0 ? [Model.p()] : props.value}
      // normalizeInitialValue -> Use this to migrate to newer versions (eg codeblock)

      // Can put overrides as plugins instead of changing editor prop: see https://plate.udecode.io/docs/plugins#with-overrides
      editableProps={{
        style: props.style,
        readOnly: !props.editMode,
        className: classNames(['slate-editor', 'overflow-auto', props.className]),
        // decorate: decorate,
        // renderElement: renderElement,
        // renderLeaf: renderLeaf,
        placeholder: props.placeholder ?? 'Enter some content here...',
        // onKeyDown: onKeyDown,
        // onFocus: emptyOnFocus,
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
      <HeadingToolbar>
        <BasicElementToolbarButtons />

        <IndentToolbarButtons />
        <ListToolbarButtons />
        <AlignToolbarButtons />

        <BasicMarkToolbarButtons />

        <TableToolbarButtons />
      </HeadingToolbar>
      {props.children}

      {/* <EditorToolbar context={props.commandContext} toolbarInsertDescs={props.toolbarInsertDescs} /> */}
    </Plate>
    // <Slate
    //   editor={editor}
    //   value={props.value.length === 0 ? [Model.p()] : props.value}
    //   onChange={onChange}
    // >
    //   {props.children}

    //   <EditorToolbar context={props.commandContext} toolbarInsertDescs={props.toolbarInsertDescs} />

    //   <Editable
    //     style={props.style}
    //     className={classNames(['slate-editor', 'overflow-auto', props.className])}
    //     readOnly={!props.editMode}
    //     decorate={decorate}
    //     renderElement={renderElement}
    //     renderLeaf={renderLeaf}
    //     placeholder={props.placeholder ?? 'Enter some content here...'}
    //     onKeyDown={onKeyDown}
    //     onFocus={emptyOnFocus}
    //     onPaste={(e) => {
    //       const pastedText = e.clipboardData?.getData('text')?.trim();
    //       const youtubeRegex =
    //         /^(?:(?:https?:)?\/\/)?(?:(?:www|m)\.)?(?:(?:youtube\.com|youtu.be))(?:\/(?:[\w-]+\?v=|embed\/|v\/)?)([\w-]+)(?:\S+)?$/;
    //       const matches = pastedText.match(youtubeRegex);
    //       if (matches != null) {
    //         // matches[0] === the entire url
    //         // matches[1] === video id
    //         const [, videoId] = matches;
    //         e.preventDefault();
    //         Transforms.insertNodes(editor, [Model.youtube(videoId)]);
    //       }
    //     }}
    //   />
    // </Slate>
  );
}, areEqual);
Editor.displayName = 'Editor';

const BasicElementToolbarButtons = () => {
  const editor = usePlateEditorRef();

  return (
    <>
      <BlockToolbarButton type={getPluginType(editor, ELEMENT_H1)} icon={<LooksOne />} />
      <BlockToolbarButton type={getPluginType(editor, ELEMENT_H2)} icon={<LooksTwo />} />
      <BlockToolbarButton type={getPluginType(editor, ELEMENT_BLOCKQUOTE)} icon={<FormatQuote />} />
      <CodeBlockToolbarButton
        type={getPluginType(editor, ELEMENT_BLOCKQUOTE)}
        icon={<CodeBlock />}
      />
    </>
  );
};

const IndentToolbarButtons = () => {
  const editor = usePlateEditorRef();

  return (
    <>
      <ToolbarButton
        onMouseDown={editor && getPreventDefaultHandler(outdent, editor)}
        icon={<FormatIndentDecrease />}
      />
      <ToolbarButton
        onMouseDown={editor && getPreventDefaultHandler(indent, editor)}
        icon={<FormatIndentIncrease />}
      />
    </>
  );
};

const ListToolbarButtons = () => {
  const editor = usePlateEditorState();

  const active = (listStyleType: string) => {
    if (!editor.selection) return false;
    let _at: Path;

    if (Range.isRange(editor.selection) && !isCollapsed(editor.selection)) {
      _at = editor.selection.focus.path;
    } else if (Range.isRange(editor.selection)) {
      _at = editor.selection.anchor.path;
    } else {
      _at = editor.selection as Path;
    }

    if (_at) {
      const node = getNode(editor, _at) as TElement;
      if (node) {
        return !!getAbove(editor, {
          at: _at,
          match: { listStyleType },
          mode: 'lowest',
        });
      }
    }
    return false;
  };
  return (
    <>
      <ListToolbarButton
        active={active('disc')}
        onMouseDown={
          editor && getPreventDefaultHandler(toggleIndentList, editor, { listStyleType: 'disc' })
        }
        type={getPluginType(editor, ELEMENT_UL)}
        icon={<FormatListBulleted />}
      />
      <ListToolbarButton
        active={active('decimal')}
        onMouseDown={
          editor && getPreventDefaultHandler(toggleIndentList, editor, { listStyleType: 'decimal' })
        }
        type={getPluginType(editor, ELEMENT_OL)}
        icon={<FormatListNumbered />}
      />
    </>
  );
};

const AlignToolbarButtons = () => {
  return (
    <>
      <AlignToolbarButton value="left" icon={<FormatAlignLeft />} />
      <AlignToolbarButton value="center" icon={<FormatAlignCenter />} />
      <AlignToolbarButton value="right" icon={<FormatAlignRight />} />
      <AlignToolbarButton value="justify" icon={<FormatAlignJustify />} />
    </>
  );
};

const BasicMarkToolbarButtons = () => {
  const editor = usePlateEditorRef();

  return (
    <>
      <MarkToolbarButton type={getPluginType(editor, MARK_BOLD)} icon={<FormatBold />} />
      <MarkToolbarButton type={getPluginType(editor, MARK_ITALIC)} icon={<FormatItalic />} />
      <MarkToolbarButton type={getPluginType(editor, MARK_UNDERLINE)} icon={<FormatUnderlined />} />
      <MarkToolbarButton
        type={getPluginType(editor, MARK_STRIKETHROUGH)}
        icon={<FormatStrikethrough />}
      />
      <MarkToolbarButton type={getPluginType(editor, MARK_CODE)} icon={<CodeAlt />} />
      <MarkToolbarButton
        type={getPluginType(editor, MARK_SUPERSCRIPT)}
        clear={getPluginType(editor, MARK_SUBSCRIPT)}
        icon={<Superscript />}
      />
      <MarkToolbarButton
        type={getPluginType(editor, MARK_SUBSCRIPT)}
        clear={getPluginType(editor, MARK_SUPERSCRIPT)}
        icon={<Subscript />}
      />
    </>
  );
};

const TableToolbarButtons = () => (
  <>
    <TableToolbarButton icon={<BorderAll />} transform={insertTable} />
    <TableToolbarButton icon={<BorderClear />} transform={deleteTable} />
    <TableToolbarButton icon={<BorderBottom />} transform={addRow} />
    <TableToolbarButton icon={<BorderTop />} transform={deleteRow} />
    <TableToolbarButton icon={<BorderLeft />} transform={addColumn} />
    <TableToolbarButton icon={<BorderRight />} transform={deleteColumn} />
  </>
);
