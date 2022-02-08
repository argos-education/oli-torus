import React from 'react';
<<<<<<< HEAD:assets/src/components/editing/nodes/table/TableEditor.tsx
import { updateModel } from 'components/editing/nodes/utils';
import * as ContentModel from 'data/content/model/nodes/types';
import { EditorProps } from 'components/editing/nodes/interfaces';
import { CaptionEditor } from 'components/editing/nodes/settings/CaptionEditor';
=======
import { updateModel } from 'components/editing/elements/utils';
import * as ContentModel from 'data/content/model/elements/types';
import { EditorProps } from 'components/editing/elements/interfaces';
import { CaptionEditor } from 'components/editing/elements/common/settings/CaptionEditor';
>>>>>>> fix-toolbar:assets/src/components/editing/nodes/table/TableElement.tsx
import { useSlate } from 'slate-react';

interface Props extends EditorProps<ContentModel.Table> {}
export const TableEditor = (props: Props) => {
  const editor = useSlate();

  const onEdit = (updated: Partial<ContentModel.Table>) =>
    updateModel<ContentModel.Table>(editor, props.model, updated);

  return (
    <div {...props.attributes} className="table-editor">
      <table>
        <tbody>{props.children}</tbody>
      </table>
      <CaptionEditor onEdit={(caption: string) => onEdit({ caption })} model={props.model} />
    </div>
  );
};
