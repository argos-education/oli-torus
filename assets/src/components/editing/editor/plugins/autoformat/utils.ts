import { AutoformatBlockRule, unwrapList, PlateEditor } from '@udecode/plate';

export const clearBlockFormat: AutoformatBlockRule['preFormat'] = (editor) =>
  unwrapList(editor as PlateEditor);
