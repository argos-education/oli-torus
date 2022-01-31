import { createPlateUI, ELEMENT_PARAGRAPH, withProps, StyledElement } from '@udecode/plate';
import { CodeEditor } from 'components/editing/nodes/blockcode/Editor';

export const pluginComponents = {
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
  code: CodeEditor,
};
