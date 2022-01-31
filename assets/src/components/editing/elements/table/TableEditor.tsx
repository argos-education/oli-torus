import React from 'react';
import { updateModel } from 'components/editing/elements/utils';
import * as ContentModel from 'data/content/model/elements/types';
import { EditorProps } from 'components/editing/elements/interfaces';
import { CaptionEditor } from 'components/editing/elements/settings/CaptionEditor';
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