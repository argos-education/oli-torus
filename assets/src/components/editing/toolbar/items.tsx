<<<<<<< HEAD
import { commandDesc as quoteCmd } from 'components/editing/nodes/commands/BlockquoteCmd';
import {
  createButtonCommandDesc,
  createToggleFormatCommand as format,
  switchType,
} from 'components/editing/nodes/commands/commands';
import { CommandDesc } from 'components/editing/nodes/commands/interfaces';
import { commandDesc as linkCmd } from 'components/editing/nodes/commands/LinkCmd';
import { ulCommandDesc as ulCmd } from 'data/content/model/nodes/list/ListsCmd';
import { isActive } from 'components/editing/utils';
import { SlateEditor } from 'data/content/model/slate';
import { audioCmdDescBuilder } from 'components/editing/nodes/commands/AudioCmd';
import { imgCmdDescBuilder } from 'components/editing/nodes/commands/ImageCmd';
import { tableCommandDesc } from 'components/editing/nodes/commands/table/TableCmd';
import { webpageCmdDesc } from 'components/editing/nodes/commands/WebpageCmd';
import { ytCmdDesc } from 'components/editing/nodes/commands/YoutubeCmd';
import { popupCmdDesc } from 'components/editing/nodes/commands/PopupCmd';
import {
  codeBlockInsertDesc,
  codeBlockToggleDesc,
} from 'components/editing/nodes/commands/BlockcodeCmd';

// const precondition = (editor: SlateEditor) => {
//   return isTopLevel(editor) && isActive(editor, Object.keys(parentTextTypes));
// };

const paragraphDesc = createButtonCommandDesc({
  icon: 'subject',
  description: 'Paragraph',
  active: (editor) =>
    isActive(editor, 'p') &&
    [headingDesc, ulCmd, quoteCmd, codeBlockToggleDesc].every((desc) => !desc.active?.(editor)),
  execute: (_ctx, editor) => switchType(editor, 'p'),
});

const quoteToggleDesc = createButtonCommandDesc({
  icon: 'format_quote',
  description: 'Quote',
  active: (e) => isActive(e, 'blockquote'),
  execute: (_ctx, editor) => switchType(editor, 'blockquote'),
});

// type: 'CommandDesc',
//   icon: () => 'format_list_bulleted',
//   description: () => 'Unordered List',
//   command: listCommandMaker('ul'),
//   active: (editor) => isActive(editor, ['ul']),

const listDesc = createButtonCommandDesc({
  icon: 'format_list_bulleted',
  description: 'List',
  active: (editor) => isActive(editor, ['ul', 'ol']),
  execute: (_ctx, editor) => switchType(editor, 'ul'),
});

const headingDesc = createButtonCommandDesc({
  icon: 'title',
  description: 'Heading',
  active: (editor) => isActive(editor, ['h1', 'h2']),
  execute: (_ctx, editor) => switchType(editor, 'h2'),
});

const underLineDesc = format({
  icon: 'format_underlined',
  mark: 'underline',
  description: 'Underline',
});

const strikethroughDesc = format({
  icon: 'strikethrough_s',
  mark: 'strikethrough',
  description: 'Strikethrough',
});

const subscriptDesc = format({
  icon: 'subscript',
  mark: 'sub',
  description: 'Subscript',
  precondition: (editor) => !isActive(editor, ['code']),
});

const superscriptDesc = format({
  icon: 'superscript',
  mark: 'sup',
  description: 'Superscript',
  precondition: (editor) => !isActive(editor, ['code']),
});

const inlineCodeDesc = format({
  icon: 'code',
  mark: 'code',
  description: 'Code',
  precondition: (editor) => !isActive(editor, ['code']),
});

export const additionalFormattingOptions = [
  underLineDesc,
  strikethroughDesc,
  inlineCodeDesc,
  subscriptDesc,
  superscriptDesc,
  popupCmdDesc,
];

const textTypes = ['paragraph', 'heading', 'list', 'quote', 'code'];

export const textTypeDescs = [
  paragraphDesc,
  headingDesc,
  listDesc,
  quoteToggleDesc,
  codeBlockToggleDesc,
];

export const formattingDropdownDesc: CommandDesc = {
  type: 'CommandDesc',
  icon: () => 'expand_more',
  description: () => 'More',
  command: {
    execute: (_context, _editor, _action) => {},
    precondition: (_editor) => true,
  },
=======
import { createButtonCommandDesc } from 'components/editing/elements/commands/commandFactories';
import { CommandDescription } from 'components/editing/elements/commands/interfaces';
import { commandDesc as linkCmd } from 'components/editing/elements/link/LinkCmd';
import { insertCodeblock } from 'components/editing/elements/blockcode/codeblockActions';
import { insertYoutube } from 'components/editing/elements/youtube/youtubeActions';
import { toggleBlockquote } from 'components/editing/elements/blockquote/blockquoteActions';
import { toggleList } from 'components/editing/elements/list/listActions';
import { Editor } from 'slate';
import {
  additionalFormattingOptions,
  toggleFormat,
} from 'components/editing/elements/marks/toggleMarkActions';
import { insertWebpage } from 'components/editing/elements/webpage/webpageActions';
import { insertTable } from 'components/editing/elements/table/commands/insertTable';
import { insertImage } from 'components/editing/elements/image/imageActions';
import { insertAudio } from 'components/editing/elements/audio/audioActions';
import { toggleHeading } from 'components/editing/elements/heading/headingActions';
import { toggleParagraph } from 'components/editing/elements/paragraph/paragraphActions';

export const formattingDropdownAction = createButtonCommandDesc({
  icon: 'expand_more',
  description: 'More',
  execute: (_context, _editor, _action) => {},
>>>>>>> fix-toolbar
  active: (e) => additionalFormattingOptions.some((opt) => opt.active?.(e)),
});

export const toggleTextTypes = [toggleParagraph, toggleHeading, toggleList, toggleBlockquote];

export const activeBlockType = (editor: Editor) =>
  toggleTextTypes.find((type) => type?.active?.(editor)) || toggleTextTypes[0];

export const addItemDropdown: CommandDescription = {
  type: 'CommandDesc',
  icon: () => 'add',
  description: () => 'Add item',
  command: {} as any,
  active: (_e) => false,
};

export const addItemActions = (onRequestMedia: any) => [
  insertTable,
  insertCodeblock,
  insertImage(onRequestMedia),
  insertYoutube,
  insertAudio(onRequestMedia),
  insertWebpage,
];

export const formatMenuCommands = [
  toggleFormat({ icon: 'format_bold', mark: 'strong', description: 'Bold' }),
  toggleFormat({ icon: 'format_italic', mark: 'em', description: 'Italic' }),
  linkCmd,
];
