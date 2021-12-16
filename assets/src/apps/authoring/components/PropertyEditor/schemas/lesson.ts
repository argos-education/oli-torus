import { UiSchema } from '@rjsf/core';
import { JSONSchema7 } from 'json-schema';
import AccordionTemplate from '../custom/AccordionTemplate';
import CustomFieldTemplate from '../custom/CustomFieldTemplate';

const lessonSchema: JSONSchema7 = {
  type: 'object',
  properties: {
    Properties: {
      type: 'object',
      title: ' Properties',
      properties: {
        title: {
          type: 'string',
          title: 'Title',
          readOnly: true,
        },
        Size: {
          type: 'object',
          title: 'Dimensions',
          properties: {
            width: { type: 'number' },
            height: { type: 'number' },
          },
        },
        Appearance: {
          type: 'object',
          title: 'Lesson Appearance',
          properties: {
            theme: {
              anyOf: [
                {
                  type: 'string',
                  title: 'Default Theme',
                  enum: ['/css/delivery_adaptive_themes_default_light.css'],
                  default: '/css/delivery_adaptive_themes_default_light.css',
                },
                { type: 'string', title: 'Custom Theme' },
              ],
            },
            customCssUrl: {
              type: 'string',
              title: 'Custom CSS URL',
            },
            backgroundImageURL: {
              type: 'string',
              title: 'Background Image URL',
            },
            backgroundImageScaleContent: {
              type: 'boolean',
              title: 'Scale Background Image to Fit',
            },
          },
        },
        FinishPanel: {
          type: 'object',
          properties: {
            logoutMessage: {
              title: 'Message',
              type: 'string',
              format: 'textarea',
            },
            logoutPanelImageURL: {
              type: 'string',
              title: 'Background URL',
            },
          },
        },
        enableHistory: {
          title: 'Enable History',
          type: 'boolean',
        },
        ScoreOverview: {
          type: 'object',
          properties: {
            enableLessonMax: { type: 'boolean', title: 'Enable a Lesson Maximum' },
            lessonMax: { type: 'number', title: 'Lesson Max' },
          },
        },
        customCSS: {
          title: 'Custom CSS',
          type: 'string',
          description: 'block of css code to be injected into style tag',
          format: 'textarea',
        },
      },
    },
    CustomLogic: {
      type: 'object',
      title: 'Custom Logic',
      properties: {
        variables: {
          type: 'string',
          title: 'Variables',
          format: 'textarea',
        },
        customScript: {
          type: 'string',
          title: 'Custom Script',
          format: 'textarea',
        },
      },
    },
  },
};

export const lessonUiSchema: UiSchema = {
  Properties: {
    'ui:ObjectFieldTemplate': AccordionTemplate,
    Size: {
      'ui:ObjectFieldTemplate': CustomFieldTemplate,
      'ui:title': 'Screen Size',
      width: {
        classNames: 'col-6',
      },
      height: {
        classNames: 'col-6',
      },
    },
    Appearance: {
      'ui:ObjectFieldTemplate': CustomFieldTemplate,
      'ui:title': 'Lesson Appearance',
    },
    FinishPanel: {
      'ui:ObjectFieldTemplate': CustomFieldTemplate,
      'ui:title': 'Finish Panel',
    },
    ScoreOverview: {
      'ui:ObjectFieldTemplate': CustomFieldTemplate,
      'ui:title': 'Score Overview',
    },
  },
  CustomLogic: {
    'ui:ObjectFieldTemplate': AccordionTemplate,
  },
};

// we don't have the actual theme urls yet,
// they will likely come from somehwere else
// const themeMap: { [key: string]: string } = {
//   'url to new theme': 'Light Responsive',
//   'default': 'LEGACY',
// };

export const transformModelToSchema = (model: any) => {
  const [themeUrl, customCssUrl] = model.additionalStylesheets;

  return {
    Properties: {
      Size: { width: model.custom.defaultScreenWidth, height: model.custom.defaultScreenHeight },
      Appearance: {
        theme: themeUrl,
        customCssUrl,
        backgroundImageURL: model.custom.backgroundImageURL,
        backgroundImageScaleContent: model.custom.backgroundImageScaleContent,
      },
      ScoreOverview: {
        enableLessonMax: model.custom.enableLessonMax,
        lessonMax: model.custom.lessonMax,
      },
      FinishPanel: {
        logoutMessage: model.custom.logoutMessage,
        logoutPanelImageURL: model.custom.logoutPanelImageURL,
      },
      title: model.title,
      customCSS: model.customCss,
      enableHistory: model.custom.allowNavigation || model.custom.enableHistory || false,
    },
    CustomLogic: {
      variables: JSON.stringify(model.custom.variables),
      customScript: model.customScript,
    },
  };
};

export const transformSchemaToModel = (schema: any) => {
  /* console.log('LESSON SCHEMA -> MODEL', schema); */

  const additionalStylesheets = [
    schema.Properties.Appearance.theme,
    schema.Properties.Appearance.customCssUrl,
  ];

  let variables = [];
  try {
    variables = JSON.parse(schema.CustomLogic.variables);
  } catch (e) {
    // console.warn('could not parse variables', e);
    // most likely just empty string
  }

  return {
    custom: {
      defaultScreenWidth: schema.Properties.Size.width,
      defaultScreenHeight: schema.Properties.Size.height,
      enableLessonMax: schema.Properties.ScoreOverview.enableLessonMax,
      lessonMax: schema.Properties.ScoreOverview.lessonMax,
      enableHistory: schema.Properties.enableHistory,
      variables,
      logoutMessage: schema.Properties.FinishPanel.logoutMessage,
      logoutPanelImageURL: schema.Properties.FinishPanel.logoutPanelImageURL,
      backgroundImageURL: schema.Properties.Appearance.backgroundImageURL,
      backgroundImageScaleContent: schema.Properties.Appearance.backgroundImageScaleContent,
    },
    additionalStylesheets,
    title: schema.Properties.title,
    customCss: schema.Properties.customCSS || '',
    customScript: schema.CustomLogic.customScript,
  };
};

export default lessonSchema;