import {
  AutoformatRule,
  ELEMENT_H1,
  ELEMENT_H2,
  ELEMENT_H3,
  ELEMENT_H4,
  ELEMENT_H5,
  ELEMENT_H6,
  ELEMENT_BLOCKQUOTE,
  ELEMENT_HR,
  setNodes,
  insertNodes,
  ELEMENT_CODE_BLOCK,
  insertEmptyCodeBlock,
  PlateEditor,
  getPluginType,
  ELEMENT_DEFAULT,
} from '@udecode/plate';
import { clearBlockFormat } from 'components/editing/editor/plugins/autoformat/utils';
import { Model } from 'data/content/model/nodes/factories';

export const autoformatBlocks: AutoformatRule[] = [
  {
    mode: 'block',
    type: ELEMENT_H1,
    match: '# ',
    preFormat: clearBlockFormat,
  },
  {
    mode: 'block',
    type: ELEMENT_H2,
    match: '## ',
    preFormat: clearBlockFormat,
  },
  {
    mode: 'block',
    type: ELEMENT_H3,
    match: '### ',
    preFormat: clearBlockFormat,
  },
  {
    mode: 'block',
    type: ELEMENT_H4,
    match: '#### ',
    preFormat: clearBlockFormat,
  },
  {
    mode: 'block',
    type: ELEMENT_H5,
    match: '##### ',
    preFormat: clearBlockFormat,
  },
  {
    mode: 'block',
    type: ELEMENT_H6,
    match: '###### ',
    preFormat: clearBlockFormat,
  },
  {
    mode: 'block',
    type: ELEMENT_BLOCKQUOTE,
    match: '> ',
    preFormat: clearBlockFormat,
  },
  {
    mode: 'block',
    type: ELEMENT_HR,
    match: ['---', '—-'],
    preFormat: clearBlockFormat,
    format: (editor) => {
      setNodes(editor, { type: ELEMENT_HR });
      insertNodes(editor, Model.p());
    },
  },
  {
    mode: 'block',
    type: ELEMENT_CODE_BLOCK,
    match: '```',
    triggerAtBlockStart: false,
    preFormat: clearBlockFormat,
    format: (editor) => {
      insertEmptyCodeBlock(editor as PlateEditor, {
        defaultType: getPluginType(editor as PlateEditor, ELEMENT_DEFAULT),
        insertNodesOptions: { select: true },
      });
    },
  },
];
