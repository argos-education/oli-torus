/* eslint-disable @typescript-eslint/no-var-requires */
const manifest = require('./manifest.json');
import register from '../customElementWrapper';
import {
  authoringObservedAttributes,
  customEvents as apiCustomEvents,
  observedAttributes as apiObservedAttributes,
} from '../partsApi';
import McqAuthor from './McqAuthor';
import { adaptivitySchema, createSchema, getCapabilities, schema, uiSchema } from './schema';

const observedAttributes: string[] = [...apiObservedAttributes, ...authoringObservedAttributes];
const customEvents: any = {
  ...apiCustomEvents,
  onConfigure: 'configure',
  onSaveConfigure: 'saveconfigure',
  onCancelConfigure: 'cancelconfigure',
};

register(McqAuthor, manifest.authoring.element, observedAttributes, {
  customEvents,
  shadow: false,
  attrs: {
    model: {
      json: true,
    },
  },
  customApi: {
    getSchema: () => schema,
    getUiSchema: () => uiSchema,
    createSchema,
    getCapabilities,
    getAdaptivitySchema: async () => adaptivitySchema,
  },
});