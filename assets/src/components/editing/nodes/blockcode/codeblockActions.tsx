import { Editor, Element, Transforms } from 'slate';
import { isActive } from '../../utils';
<<<<<<< HEAD:assets/src/components/editing/nodes/commands/BlockcodeCmd.tsx
import { createButtonCommandDesc, switchType } from 'components/editing/nodes/commands/commands';
import { Model } from 'data/content/model/nodes/factories';
=======
import { createButtonCommandDesc } from 'components/editing/elements/commands/commandFactories';
import { Model } from 'data/content/model/elements/factories';
import { switchType } from 'components/editing/elements/commands/toggleTextTypes';
>>>>>>> fix-toolbar:assets/src/components/editing/nodes/blockcode/codeblockActions.tsx

const ui = {
  icon: 'code',
  description: 'Code (Block)',
};

export const insertCodeblock = createButtonCommandDesc({
  ...ui,
  execute: (_context, editor) => {
    if (!editor.selection) return;
    Transforms.insertNodes(editor, Model.code(), { at: editor.selection });
  },
  precondition: (editor) => {
    return !isActive(editor, 'table');
  },
});

export const toggleCodeblock = createButtonCommandDesc({
  ...ui,
  active: (editor) => isActive(editor, 'code'),
  execute: (_ctx, editor) => switchType(editor, 'code'),
});

export const codeLanguageDesc = (editor: Editor) => {
  const [topLevel] = [...Editor.nodes(editor)][1];
  const lang = Element.isElement(topLevel) && topLevel.type === 'code' ? topLevel.language : 'Text';

  return createButtonCommandDesc({
    icon: '',
    description: lang,
    active: (_editor) => false,
    execute: (_ctx, _editor) => {},
  });
};
