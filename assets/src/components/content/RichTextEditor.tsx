import { useAuthoringElementContext } from 'components/activities/AuthoringElement';
import { ErrorBoundary } from 'components/common/ErrorBoundary';
import { CommandContext } from 'components/editing/nodes/commands/interfaces';
import { Editor } from 'components/editing/editor/Editor';
import { NormalizerContext } from 'components/editing/editor/normalizers/normalizer';
import { getToolbarForContentType } from 'components/editing/toolbar/utils';
import { ProjectSlug } from 'data/types';
import React from 'react';
import { Editor as SlateEditor, Operation } from 'slate';
import { classNames } from 'utils/classNames';
import { TNode } from '@udecode/plate';

type Props = {
  id: string;
  projectSlug: ProjectSlug;
  editMode: boolean;
  className?: string;
  value: TNode[];
  onEdit: (value: TNode[]) => void;
  placeholder?: string;
  onRequestMedia?: any;
  style?: React.CSSProperties;
  commandContext?: CommandContext;
  normalizerContext?: NormalizerContext;
  preventLargeContent?: boolean;
};
export const RichTextEditor: React.FC<Props> = (props) => {
  // Support content persisted when RichText had a `model` property.
  const value = (props.value as any).model ? (props.value as any).model : props.value;

  return (
    <div className={classNames(['rich-text-editor', props.className])}>
      <ErrorBoundary>
        <Editor
          id={props.id}
          normalizerContext={props.normalizerContext}
          commandContext={props.commandContext || { projectSlug: props.projectSlug }}
          editMode={props.editMode}
          value={value}
          onEdit={props.onEdit}
          toolbarInsertDescs={[]}
          placeholder={props.placeholder}
          style={props.style}
        >
          {props.children}
        </Editor>
      </ErrorBoundary>
    </div>
  );
};

export const RichTextEditorConnected: React.FC<Omit<Props, 'projectSlug' | 'editMode'>> = (
  props,
) => {
  const { editMode, projectSlug, onRequestMedia } = useAuthoringElementContext();
  return (
    <RichTextEditor
      {...props}
      editMode={editMode}
      projectSlug={projectSlug}
      onRequestMedia={onRequestMedia}
    />
  );
};
