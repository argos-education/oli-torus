import * as Immutable from 'immutable';
import React from 'react';
import { PersistenceStrategy } from 'data/persistence/PersistenceStrategy';
import { DeferredPersistenceStrategy } from 'data/persistence/DeferredPersistenceStrategy';
import { ResourceContent, ResourceContext,
  Activity, ActivityMap, createDefaultStructuredContent } from 'data/content/resource';
import { Objective } from 'data/content/objective';
import { ActivityEditorMap } from 'data/content/editors';
import { Editors } from './Editors';
import { Objectives } from './Objectives';
import { Outline } from './Outline';
import { TitleBar } from '../content/TitleBar';
import { UndoRedo } from '../content/UndoRedo';
import { PersistenceStatus } from 'components/content/PersistenceStatus';
import { AddResourceContent } from '../content/AddResourceContent';
import { ProjectSlug, ResourceSlug, ObjectiveSlug } from 'data/types';
import { makeRequest } from 'data/persistence/common';
import { UndoableState, processRedo, processUndo, processUpdate, init } from './undo';
import { releaseLock, acquireLock } from 'data/persistence/lock';

export interface ResourceEditorProps extends ResourceContext {
  editorMap: ActivityEditorMap;   // Map of activity types to activity elements
  activities: ActivityMap;
}

// This is the state of our resource that is undoable
type Undoable = {
  title: string,
  content: Immutable.List<ResourceContent>,
  objectives: Immutable.List<ObjectiveSlug>,
};

type ResourceEditorState = {
  undoable: UndoableState<Undoable>,
  allObjectives: Immutable.List<Objective>,
  activities: Immutable.Map<string, Activity>,
  editMode: boolean,
  persistence: 'idle' | 'pending' | 'inflight',
};

// Creates a function that when invoked submits a save request
function prepareSaveFn(project: ProjectSlug, resource: ResourceSlug, body: any) {
  return () => {
    const params = {
      method: 'PUT',
      body: JSON.stringify({ update: body }),
      url: `/project/${project}/resource/${resource}`,
    };

    return makeRequest(params);
  };
}

// Ensures that there is some default content if the initial content
// of this resource is empty
function withDefaultContent(content: ResourceContent[]) {
  return content.length > 0
    ? content
    : [createDefaultStructuredContent()];
}


function registerUnload(strategy: PersistenceStrategy) {
  return window.addEventListener('beforeunload', (event) => {
    strategy.destroy();
  });
}

function unregisterUnload(listener: any) {
  window.removeEventListener('beforeunload', listener);
}

// The resource editor
export class ResourceEditor extends React.Component<ResourceEditorProps, ResourceEditorState> {

  persistence: PersistenceStrategy;
  windowUnloadListener: any;

  constructor(props: ResourceEditorProps) {
    super(props);

    const { title, objectives, allObjectives, content, activities } = props;

    this.state = {
      editMode: true,
      undoable: init({
        title,
        objectives: Immutable.List<ObjectiveSlug>(objectives),
        content: Immutable.List<ResourceContent>(withDefaultContent(content)),
      }),
      persistence: 'idle',
      allObjectives: Immutable.List<Objective>(allObjectives),
      activities: Immutable.Map<string, Activity>(
        Object.keys(activities).map(k => [k, activities[k]])),
    };

    this.persistence = new DeferredPersistenceStrategy();

    this.update = this.update.bind(this);
    this.undo = this.undo.bind(this);
    this.redo = this.redo.bind(this);

  }

  componentDidMount() {

    const { projectSlug, resourceSlug } = this.props;

    this.persistence.initialize(
      acquireLock.bind(undefined, projectSlug, resourceSlug),
      releaseLock.bind(undefined, projectSlug, resourceSlug),
      () => {},
      () => {},
      persistence => this.setState({ persistence }),
    ).then((editMode) => {
      this.setState({ editMode });
      if (editMode) {
        this.windowUnloadListener = registerUnload(this.persistence);
      }
    });
  }

  componentWillUnmount() {
    this.persistence.destroy();
    if (this.windowUnloadListener !== null) {
      unregisterUnload(this.windowUnloadListener);
    }
  }

  update(update: Partial<Undoable>) {
    this.setState(
      { undoable: processUpdate(this.state.undoable, update) },
      () => this.save());
  }

  save() {
    const { projectSlug, resourceSlug } = this.props;
    this.persistence.save(
      prepareSaveFn(projectSlug, resourceSlug, this.state.undoable.current));
  }

  undo() {
    this.setState({ undoable: processUndo(this.state.undoable) },
    () => this.save());
  }

  redo() {
    this.setState({ undoable: processRedo(this.state.undoable) },
    () => this.save());
  }

  render() {

    const props = this.props;
    const state = this.state;

    const onEdit = (content: Immutable.List<ResourceContent>) => {
      this.update({ content });
    };

    const onTitleEdit = (title: string) => {
      this.update({ title });
    };

    const onAddItem = (c : ResourceContent, a? : Activity) => {
      this.update({ content: this.state.undoable.current.content.push(c) });
      if (a) {
        this.setState({ activities: this.state.activities.set(a.activitySlug, a) });
      }
    };

    return (
      <div>
        <TitleBar
          title={state.undoable.current.title}
          onTitleEdit={onTitleEdit}
          editMode={this.state.editMode}>
          <PersistenceStatus persistence={this.state.persistence}/>
          <UndoRedo
            canRedo={this.state.undoable.redoStack.size > 0}
            canUndo={this.state.undoable.undoStack.size > 0}
            onUndo={this.undo} onRedo={this.redo}/>
          <AddResourceContent
            editMode={this.state.editMode}
            onAddItem={onAddItem}
            editorMap={props.editorMap}
            resourceContext={props}
          />
        </TitleBar>
        <Objectives
          editMode={this.state.editMode}
          selected={this.state.undoable.current.objectives}
          objectives={this.state.allObjectives}
          onEdit={objectives => this.update({ objectives })} />
        <div className="d-flex flex-row align-items-start">
          <Outline {...props} editMode={this.state.editMode}
            activities={this.state.activities}
            onEdit={c => onEdit(c)} content={state.undoable.current.content}/>
          <Editors {...props} editMode={this.state.editMode}
            activities={this.state.activities}
            onEdit={c => onEdit(c)} content={state.undoable.current.content}/>
        </div>
      </div>
    );
  }
}
