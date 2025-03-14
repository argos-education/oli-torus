import { HasParts } from 'components/activities/types';
import { getPartById } from 'data/activities/model/utils';
import { ActivityTrigger, sameTrigger } from 'data/triggers';
import { findTrigger } from './TriggerUtils';

export const TriggerActions = {
  addTrigger(trigger: ActivityTrigger, partId: string) {
    return (model: HasParts) => {
      const part = getPartById(model, partId);
      if (part.triggers) part.triggers.push(trigger);
      else part.triggers = [trigger];
    };
  },

  removeTrigger(trigger: ActivityTrigger, partId: string) {
    return (model: HasParts) => {
      const part = getPartById(model, partId);
      if (part.triggers) part.triggers = part.triggers.filter((t) => !sameTrigger(t, trigger));
    };
  },

  setTriggerPrompt(trigger: ActivityTrigger, partId: string, prompt: string) {
    return (model: HasParts) => {
      const part = getPartById(model, partId);
      if (part.triggers) {
        const target = findTrigger(model, partId, trigger);
        if (target) target.prompt = prompt;
      }
    };
  },
};
