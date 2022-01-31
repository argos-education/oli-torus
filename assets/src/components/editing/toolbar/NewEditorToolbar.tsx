import {
  usePlateEditorState,
  PlateEditor,
  isExpanded,
  TElement,
  getPluginType,
  someNode,
  isSelectionAtBlockStart,
  insertNodes,
  getText,
  ELEMENT_H1,
  ELEMENT_H2,
  ELEMENT_BLOCKQUOTE,
  getPreventDefaultHandler,
  outdent,
  indent,
  isCollapsed,
  getNode,
  getAbove,
  ListToolbarButton,
  toggleIndentList,
  ELEMENT_UL,
  ELEMENT_OL,
  AlignToolbarButton,
  MARK_BOLD,
  MARK_ITALIC,
  MARK_UNDERLINE,
  MARK_STRIKETHROUGH,
  MARK_CODE,
  MARK_SUPERSCRIPT,
  MARK_SUBSCRIPT,
  TableToolbarButton,
  insertTable,
  deleteTable,
  addRow,
  deleteRow,
  addColumn,
  deleteColumn,
  ImageToolbarButton,
  ColorPickerToolbarDropdown,
  MARK_COLOR,
  MARK_BG_COLOR,
  LineHeightToolbarDropdown,
  LinkToolbarButton,
  MediaEmbedToolbarButton,
  ELEMENT_TABLE,
} from '@udecode/plate';
import {
  BlockToolbarButton,
  ToolbarButton,
  MarkToolbarButton,
  HeadingToolbar,
  ToolbarDropdown,
} from '@udecode/plate-ui-toolbar';
import { DropdownButton } from 'components/editing/toolbar/buttons/DropdownButton';
import { addDesc, formattingDropdownDesc } from 'components/editing/toolbar/items';
import { Toolbar } from 'components/editing/toolbar/Toolbar';
import { isActive } from 'components/editing/utils';
import { Model } from 'data/content/model/nodes/factories';
import React from 'react';
import { Path, Range } from 'slate';
import { CodeBlock, CodeAlt, Check, Link } from 'styled-icons/boxicons-regular';
import {
  LooksOne,
  LooksTwo,
  FormatQuote,
  FormatIndentDecrease,
  FormatIndentIncrease,
  FormatListBulleted,
  FormatListNumbered,
  FormatAlignLeft,
  FormatAlignCenter,
  FormatAlignRight,
  FormatAlignJustify,
  FormatBold,
  FormatItalic,
  FormatUnderlined,
  FormatStrikethrough,
  Superscript,
  Subscript,
  BorderAll,
  BorderClear,
  BorderBottom,
  BorderTop,
  BorderLeft,
  BorderRight,
  Image,
  FontDownload,
  FormatColorText,
  LineWeight,
  OndemandVideo,
} from 'styled-icons/material';

const BasicElementToolbarButtons = () => {
  const editor = usePlateEditorState();

  return (
    <>
      <BlockToolbarButton type={getPluginType(editor, ELEMENT_H1)} icon={<LooksOne />} />
      <BlockToolbarButton type={getPluginType(editor, ELEMENT_H2)} icon={<LooksTwo />} />
      <BlockToolbarButton type={getPluginType(editor, ELEMENT_BLOCKQUOTE)} icon={<FormatQuote />} />
    </>
  );
};

const IndentToolbarButtons = () => {
  const editor = usePlateEditorState();

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
  const editor = usePlateEditorState();

  return (
    <>
      <MarkToolbarButton type={getPluginType(editor, MARK_BOLD)} icon={<FormatBold />} />
      <MarkToolbarButton type={getPluginType(editor, MARK_ITALIC)} icon={<FormatItalic />} />
      <MarkToolbarButton type={getPluginType(editor, MARK_UNDERLINE)} icon={<FormatUnderlined />} />
    </>
  );
};

const AdvancedMarkToolbarButtons = () => {
  const editor = usePlateEditorState();

  return (
    <DropdownButton description={formattingDropdownDesc}>
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
      <ColorPickerToolbarDropdown
        active
        pluginKey={MARK_COLOR}
        icon={<FormatColorText />}
        selectedIcon={<Check />}
        tooltip={{ content: 'Text color' }}
      />
      <ColorPickerToolbarDropdown
        pluginKey={MARK_BG_COLOR}
        icon={<FontDownload />}
        selectedIcon={<Check />}
        tooltip={{ content: 'Highlight color' }}
      />
    </DropdownButton>
  );
};

const TableToolbarButtons = () => {
  const editor = usePlateEditorState();

  return (
    <>
      <TableToolbarButton icon={<BorderAll />} transform={insertTable} />
      {isActive(editor, ELEMENT_TABLE) && (
        <>
          <TableToolbarButton icon={<BorderBottom />} transform={addRow} />
          <TableToolbarButton icon={<BorderTop />} transform={deleteRow} />
          <TableToolbarButton icon={<BorderLeft />} transform={addColumn} />
          <TableToolbarButton icon={<BorderRight />} transform={deleteColumn} />
        </>
      )}
    </>
  );
};

export const NewEditorToolbar = () => {
  return (
    <>
      <Toolbar.Group>
        <BasicElementToolbarButtons />
        <ListToolbarButtons />
      </Toolbar.Group>

      <Toolbar.Group>
        <LinkToolbarButton icon={<Link />} />
        <AlignToolbarButtons />
        <IndentToolbarButtons />
        <BasicMarkToolbarButtons />
        <AdvancedMarkToolbarButtons />
      </Toolbar.Group>

      <Toolbar.Group>
        <DropdownButton description={addDesc}>
          <MediaEmbedToolbarButton icon={<OndemandVideo />} />
          <ImageToolbarButton icon={<Image />} />
          <CodeBlockToolbarButton />
          <TableToolbarButtons />
        </DropdownButton>
      </Toolbar.Group>
    </>
  );
};

const CodeBlockToolbarButton = () => {
  const editor = usePlateEditorState();
  const insertCodeBlock = (editor: PlateEditor) => {
    if (!editor.selection || isExpanded(editor.selection)) return;
    const matchCodeElements = (node: TElement) => node.type === getPluginType(editor, 'code');
    if (someNode(editor, { match: matchCodeElements })) return;

    if (!isSelectionAtBlockStart(editor)) editor.insertBreak();
    insertNodes(editor, Model.code(getText(editor, editor.selection)), { select: true });
  };

  return (
    <BlockToolbarButton
      onMouseDown={getPreventDefaultHandler(insertCodeBlock, editor)}
      type={getPluginType(editor, 'code')}
      icon={<CodeBlock />}
    />
  );
};
