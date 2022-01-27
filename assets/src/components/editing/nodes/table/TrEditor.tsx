import React from 'react';
import { EditorProps } from 'components/editing/nodes/interfaces';
import { TableRow } from 'data/content/model/nodes/types';

export const TrEditor = (props: EditorProps<TableRow>) => {
  return <tr {...props.attributes}>{props.children}</tr>;
};
