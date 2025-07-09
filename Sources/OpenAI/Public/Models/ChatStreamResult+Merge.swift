import Foundation

func updated(_ string: String?, with anotherString: String?) -> String? {
    guard let anotherString = anotherString else {
        return string
    }
    
    return (string ?? "").appending(anotherString)
}

extension ChatStreamResult.Choice.ChoiceDelta.ChoiceDeltaToolCall.ChoiceDeltaToolCallFunction {
    public func merged(with chunk: Self) -> Self {
        .init(
            arguments: updated(arguments, with: chunk.arguments),
            name: updated(name, with: chunk.name)
        )
    }
}

extension ChatStreamResult.Choice.ChoiceDelta.ChoiceDeltaToolCall {
    public func merged(with chunk: Self) -> Self {
        var function: ChoiceDeltaToolCallFunction?
        if let selfFunction = self.function, let chunkFunction = chunk.function {
            function = selfFunction.merged(with: chunkFunction)
        } else {
            guard let chunkFunction = chunk.function else {
                return self
            }
            
            function = chunkFunction
        }
        
        return .init(
            index: index,
            id: chunk.id ?? id,
            function: function
        )
    }
}

extension ChatStreamResult.Choice.ChoiceDelta {
    public func merged(with chunk: Self) -> Self {
        var updatedToolCalls = toolCalls
        
        // merge tool calls if needed
        if let toolCalls = chunk.toolCalls {
            updatedToolCalls = updatedToolCalls ?? []
            for toolCall in toolCalls {
                if let existingIndex = updatedToolCalls!.firstIndex(where: { $0.index == toolCall.index }) {
                    updatedToolCalls![existingIndex] = updatedToolCalls![existingIndex].merged(with: toolCall)
                } else {
                    updatedToolCalls!.append(toolCall)
                }
            }
        }
                
        return .init(
            content: updated(content, with: chunk.content),
            audio: nil,
            role: chunk.role ?? role,
            toolCalls: updatedToolCalls,
            _reasoning: updated(_reasoning, with: chunk._reasoning),
            _reasoningContent: updated(_reasoningContent, with: chunk._reasoningContent)
        )
    }
}

extension ChatStreamResult.Choice {
    public func merged(with chunk: Self) -> Self {
        .init(
            index: index,
            delta: delta.merged(with: chunk.delta),
            finishReason: chunk.finishReason ?? finishReason,
            logprobs: chunk.logprobs ?? logprobs
        )
    }
}

extension ChatStreamResult {
    public func merged(with chunk: Self) -> Self {
        var updatedChoices = choices
        
        // merge choices
        for choice in chunk.choices {
            if let existingIndex = updatedChoices.firstIndex(where: { $0.index == choice.index }) {
                updatedChoices[existingIndex] = updatedChoices[existingIndex].merged(with: choice)
            } else {
                updatedChoices.append(choice)
            }
        }
        
        return .init(
            id: chunk.id,
            object: chunk.object,
            created: chunk.created,
            model: chunk.model,
            choices: updatedChoices,
            systemFingerprint: chunk.systemFingerprint ?? systemFingerprint,
            usage: chunk.usage ?? usage,
            serviceTier: chunk.serviceTier,
            citations: chunk.citations
        )
    }
}
