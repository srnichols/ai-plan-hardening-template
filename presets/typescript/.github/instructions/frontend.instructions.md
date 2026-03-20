---
description: TypeScript frontend patterns — React, component architecture, state management
applyTo: '**/*.tsx,**/*.jsx,**/components/**'
---

# TypeScript Frontend Patterns

## Component Architecture

### File Organization
```
src/
├── components/        # Reusable UI components
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.test.tsx
│   │   └── Button.module.css
│   └── ...
├── pages/             # Route-level components
├── hooks/             # Custom React hooks
├── services/          # API client, auth, state
├── types/             # Shared TypeScript types
└── utils/             # Pure utility functions
```

### Component Patterns

```tsx
// ✅ Typed props with interface
interface UserCardProps {
  user: User;
  onEdit: (id: string) => void;
  isLoading?: boolean;
}

export function UserCard({ user, onEdit, isLoading = false }: UserCardProps) {
  if (isLoading) return <Skeleton />;
  
  return (
    <div className="user-card">
      <h3>{user.name}</h3>
      <button onClick={() => onEdit(user.id)}>Edit</button>
    </div>
  );
}
```

## State Management

### Server State (TanStack Query)
```tsx
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: () => api.getUsers(),
  });
}

function useCreateUser() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateUserInput) => api.createUser(data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['users'] }),
  });
}
```

## Non-Negotiable Rules

### Type Safety
```tsx
// ❌ NEVER: `any` in props or state
const [data, setData] = useState<any>(null);

// ✅ ALWAYS: Explicit types
const [data, setData] = useState<User | null>(null);
```

### Error Boundaries
```tsx
// ✅ Wrap route-level components
<ErrorBoundary fallback={<ErrorPage />}>
  <UserDashboard />
</ErrorBoundary>
```

### Accessibility
```tsx
// ✅ Always include aria attributes for interactive elements
<button aria-label="Delete user" onClick={handleDelete}>
  <TrashIcon />
</button>
```
