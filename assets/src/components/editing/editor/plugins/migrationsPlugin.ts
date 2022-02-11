import {
  createPluginFactory,
  getAbove,
  getNodes,
  PlateEditor,
  toggleIndentList,
  WithOverride,
} from '@udecode/plate';
import { Element, Path } from 'slate';

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

export const createMigrationsPlugin = createPluginFactory<{
  rules: {
    match: (n: Node, p: Path) => boolean;
    migrate: (editor: PlateEditor, n: Node, p: Path) => void;
  }[];
}>({
  key: 'migrateModel',
  withOverrides: migrateModel,
  options: {
    rules: [
      {
        // TODO: unwrap ol/ul, AFTER this (so indent stays).
        // TODO: Change table editor to use most of the plate editor but with caption support
        match: (node) => Element.isElement(node) && node.type === 'li',
        migrate: (editor, node, path) => {
          const parent = getAbove(editor, {
            match: (e) => Element.isElement(e) && (e.type === 'ol' || e.type === 'ul'),
          });
          const indentLevel = [
            ...getNodes(editor, {
              match: (e) => Element.isElement(e) && (e.type === 'ul' || e.type === 'ol'),
            }),
          ].length;
          toggleIndentList(editor, {
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
});
