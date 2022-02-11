import {
  ELEMENT_IMAGE,
  ELEMENT_MEDIA_EMBED,
  ELEMENT_HR,
  ELEMENT_PARAGRAPH,
  ELEMENT_H1,
  ELEMENT_H2,
  ELEMENT_H3,
  ELEMENT_H4,
  ELEMENT_H5,
  ELEMENT_H6,
  isBlockAboveEmpty,
  isSelectionAtBlockStart,
  isCollapsed,
  getBlockAbove,
  getNodes,
  isElement,
  isType,
  ELEMENT_DEFAULT,
  unsetNodes,
  ELEMENT_TD,
  KEYS_HEADING,
  ELEMENT_BLOCKQUOTE,
  ELEMENT_TODO_LI,
  PlateEditor,
} from '@udecode/plate';
import { autoformatRules } from 'components/editing/editor/plugins/autoformat/rules';

const resetBlockTypesCommonRule = {
  types: [ELEMENT_BLOCKQUOTE, ELEMENT_TODO_LI],
  defaultType: ELEMENT_PARAGRAPH,
};

export const pluginConfig = {
  selectOnBackspace: {
    options: {
      query: {
        allow: [ELEMENT_IMAGE, ELEMENT_MEDIA_EMBED, ELEMENT_HR],
      },
    },
  },
  lineHeight: {
    inject: {
      props: {
        defaultNodeValue: 'normal',
        validTypes: [
          ELEMENT_PARAGRAPH,
          ELEMENT_H1,
          ELEMENT_H2,
          ELEMENT_H3,
          ELEMENT_H4,
          ELEMENT_H5,
          ELEMENT_H6,
        ],
      },
    },
  },
  indent: {
    inject: {
      props: {
        validTypes: [ELEMENT_PARAGRAPH, ELEMENT_H2],
      },
    },
  },
  align: {
    inject: {
      props: {
        validTypes: [
          ELEMENT_PARAGRAPH,
          ELEMENT_H1,
          ELEMENT_H2,
          ELEMENT_H3,
          ELEMENT_H4,
          ELEMENT_H5,
          ELEMENT_H6,
        ],
      },
    },
  },
  autoformat: {
    options: {
      rules: [...autoformatRules],
    },
  },
  resetNode: {
    options: {
      rules: [
        {
          ...resetBlockTypesCommonRule,
          hotkey: 'Enter',
          predicate: isBlockAboveEmpty,
        },
        {
          ...resetBlockTypesCommonRule,
          hotkey: 'Backspace',
          predicate: isSelectionAtBlockStart,
        },
      ],
    },
    then: (editor: PlateEditor) => {
      if (!editor.selection || !isCollapsed(editor.selection)) return;
      const node = getBlockAbove(editor)?.[0];
      console.log([...getNodes(editor, { at: node?.[1] })]);
      if (isElement(node) && isType(editor, node, ELEMENT_DEFAULT))
        unsetNodes(editor, ['listStyleType', 'listStart'], {
          at: node[1],
          match: (e) => isElement(e) && e.type === 'p',
        });
    },
  },
  softBreak: {
    options: {
      rules: [
        { hotkey: 'shift+enter' },
        {
          hotkey: 'enter',
          query: {
            allow: [ELEMENT_TD],
          },
        },
      ],
    },
  },
  exitBreak: {
    options: {
      rules: [
        {
          hotkey: 'mod+enter',
        },
        {
          hotkey: 'mod+shift+enter',
          before: true,
        },
        {
          hotkey: 'enter',
          query: {
            start: true,
            end: true,
            allow: KEYS_HEADING,
          },
        },
        {
          hotkey: 'esc',
          query: {
            end: true,
            allow: 'code',
          },
        },
      ],
    },
  },

  trailingBlock: { type: ELEMENT_PARAGRAPH },
};
