import { MultiInput, MultiInputType } from 'components/activities/multi_input/schema';
<<<<<<< HEAD:assets/src/components/editing/nodes/inputref/commands.tsx
import { CommandDesc } from 'components/editing/nodes/commands/interfaces';
=======
import { CommandDescription } from 'components/editing/elements/commands/interfaces';
>>>>>>> fix-toolbar:assets/src/components/editing/nodes/inputref/inputrefActions.tsx

export const initCommands = (
  model: MultiInput,
  setInputType: (id: string, updated: MultiInputType) => void,
): CommandDescription[] => {
  const makeCommand = (description: string, type: MultiInputType): CommandDescription => ({
    type: 'CommandDesc',
    icon: () => '',
    description: () => description,
    active: () => model.inputType === type,
    command: {
      execute: (_context, _editor, _params) => {
        model.inputType !== type && setInputType(model.id, type);
      },
      precondition: () => true,
    },
  });

  return [
    makeCommand('Dropdown', 'dropdown'),
    makeCommand('Text', 'text'),
    makeCommand('Number', 'numeric'),
  ];
};
