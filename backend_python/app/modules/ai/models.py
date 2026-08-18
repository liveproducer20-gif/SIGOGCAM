from pydantic import BaseModel, Field


class CodeGenerateInput(BaseModel):
    prompt: str = Field(min_length=1, max_length=8000)
    context: str | None = Field(default=None, max_length=4000, description="Additional context (file contents, etc.)")
    language: str | None = Field(default=None, description="Target language hint")


class ChatInput(BaseModel):
    message: str = Field(min_length=1, max_length=8000)
    context: str | None = Field(default=None, max_length=4000)
