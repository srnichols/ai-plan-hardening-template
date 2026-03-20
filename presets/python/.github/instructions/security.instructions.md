---
description: Python security patterns — FastAPI auth, Pydantic validation, secrets
applyTo: '**/*.py'
---

# Python Security Patterns

## Input Validation (Pydantic)

```python
from pydantic import BaseModel, EmailStr, Field

class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)
    role: Literal["user", "admin"]

# FastAPI validates automatically
@router.post("/users")
async def create_user(request: CreateUserRequest):
    return await user_service.create(request)
```

## Authentication

### JWT / OAuth2 (FastAPI)
```python
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=["RS256"])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    return await user_service.get_user(user_id)
```

## Secrets Management

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    jwt_secret: str = Field(min_length=32)
    redis_url: str = "redis://localhost:6379"
    debug: bool = False

    model_config = SettingsConfigDict(env_file=".env")

# ❌ NEVER: Hardcoded secrets
DB_PASSWORD = "secret123"

# ✅ ALWAYS: Pydantic settings (validated from env)
settings = Settings()
```

## SQL Injection Prevention

```python
# ❌ NEVER: f-strings in SQL
query = f"SELECT * FROM users WHERE id = '{user_id}'"

# ✅ ALWAYS: Parameterized
result = await conn.fetch("SELECT * FROM users WHERE id = $1", user_id)

# ✅ BEST: Use ORM
user = await session.execute(select(User).where(User.id == user_id))
```

## Type Safety

```python
# ❌ NEVER: `Any` type
def process_data(data: Any) -> Any: ...

# ✅ ALWAYS: Explicit types
def process_data(data: UserInput) -> ProcessedUser: ...

# ❌ NEVER: Bare except
try:
    ...
except:
    pass

# ✅ ALWAYS: Specific exceptions
try:
    ...
except ValueError as e:
    logger.error("Validation failed", exc_info=e)
    raise
```

## CORS Configuration

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,  # From env, not hardcoded
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)
```
