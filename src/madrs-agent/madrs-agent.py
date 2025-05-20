from langchain_core.language_models.chat_models import BaseChatModel
from langchain_core.prompts import PromptTemplate
from langgraph.graph import END, START, MessagesState, StateGraph

def build_rater(llm: BaseChatModel):
    class RaterState(MessagesState):
        transcript: str
        primer: str


    def build_prompt(state: RaterState):
        prompt_template = PromptTemplate.from_template(
            """
            You are an expert in psychiatric assessments and depression. For your
            recollection, consider the following primer on MADRS interviews:

            ---

            {primer}

            ---

            Using this information, provide the most accurate assessment of the
            following transcription of a MADRS interview. Provide your scores for
            each of the items described in the primer, providing a best guess for
            apparent sadness, together with a brief justification/discussion.

            ---

            {transcript}
            """
        )
        return {
            "messages": prompt_template.invoke(
                {
                    "transcript": state["transcript"],
                    "primer": state["primer"]
                }
            ).to_messages()
        }

    def invoke_llm(state: RaterState):
        return { "messages": llm.invoke(state["messages"]) }

    return (
        StateGraph(RaterState)
        .add_node("build_prompt", build_prompt)
        .add_node("invoke_llm", invoke_llm)
        .add_edge(START, "build_prompt")
        .add_edge("build_prompt", "invoke_llm")
        .add_edge("invoke_llm", END)
        .compile()
    )
