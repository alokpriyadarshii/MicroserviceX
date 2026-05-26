package org.springframework.samples.animalclinic.genai;

import java.util.Locale;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.MessageChatMemoryAdvisor;
import org.springframework.ai.chat.client.advisor.SimpleLoggerAdvisor;
import org.springframework.ai.chat.memory.ChatMemory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * This REST controller is being invoked by the in order to interact with the LLM
 *
 * @author Oded Shopen
 */
@RestController
@RequestMapping("/")
public class AnimalclinicChatClient {

    private static final Logger LOG = LoggerFactory.getLogger(AnimalclinicChatClient.class);

	// ChatModel is the primary interfaces for interacting with an LLM
	// it is a request/response interface that implements the ModelModel
	// interface. Make suer to visit the source code of the ChatModel and
	// checkout the interfaces in the core Spring AI package.
	private final ChatClient chatClient;

	private final String openAiApiKey;

	public AnimalclinicChatClient(ChatClient.Builder builder, ChatMemory chatMemory,
                               AnimalclinicTools animalclinicTools,
                               @Value("${spring.ai.openai.api-key:}") String openAiApiKey) {
        this.openAiApiKey = openAiApiKey;
        // @formatter:off
		this.chatClient = builder
				.defaultSystem("""
                          You are a friendly AI assistant designed to help with the management of a veterinarian animal clinic called Spring Animal Clinic.
                          Your job is to answer questions about and to perform actions on the user's behalf, mainly around
                          veterinarians, owners, owners' pets and owners' visits.
                          You are required to answer an a professional manner. If you don't know the answer, politely tell the user
                          you don't know the answer, then ask the user a followup question to try and clarify the question they are asking.
                          If you do know the answer, provide the answer but do not provide any additional followup questions.
                          When dealing with vets, if the user is unsure about the returned results, explain that there may be additional data that was not returned.
                          Only if the user is asking about the total number of all vets, answer that there are a lot and ask for some additional criteria.
                          For owners, pets or visits - provide the correct data.
                          """)
				.defaultAdvisors(
						// Chat memory helps us keep context when using the chatbot for up to 10 previous messages.
                        MessageChatMemoryAdvisor.builder(chatMemory)
                            .order(10)
                            .build(),
						new SimpleLoggerAdvisor()
						)
                .defaultTools(animalclinicTools)
				.build();
  }

  @PostMapping("/chatclient")
  public String exchange(@RequestBody String query) {
      if (!hasConfiguredOpenAiApiKey()) {
          return localResponse(query);
      }

	  try {
		  //All chatbot messages go through this endpoint
		  //and are passed to the LLM
		  return this.chatClient
              .prompt()
              .user(query)
              .call()
              .content();
	  } catch (Exception exception) {
          LOG.error("Error processing chat message", exception);
 	      return localResponse(query);
	  }
  }

  private boolean hasConfiguredOpenAiApiKey() {
      if (openAiApiKey == null || openAiApiKey.isBlank()) {
          return false;
      }

      String configuredKey = openAiApiKey.trim();
      return !"demo".equalsIgnoreCase(configuredKey)
          && !"your_api_key_here".equalsIgnoreCase(configuredKey);
  }

  private String localResponse(String query) {
      String message = normalizeQuery(query);
      String normalizedMessage = message.toLowerCase(Locale.ROOT);

      if (normalizedMessage.isBlank()) {
          return "Hi! I am the Animal Clinic assistant. Ask me about owners, pets, visits, or veterinarians.";
      }

      if (normalizedMessage.matches(".*\\b(hi|hello|hey)\\b.*")) {
          return "Hello! I am the Animal Clinic assistant. I can help with owners, pets, visits, and veterinarians.";
      }

      if (normalizedMessage.contains("help")) {
          return """
              I can help with Animal Clinic questions about:

              - owners and their pets
              - veterinarians
              - visits and appointments
              - adding owners or pets
              """;
      }

      if (normalizedMessage.contains("owner")) {
          return "I can help you find owners or add a new owner. Try asking for an owner by name, or ask to register a new owner.";
      }

      if (normalizedMessage.contains("pet")) {
          return "I can help with pet records. Tell me the owner and the pet details you want to look up or add.";
      }

      if (normalizedMessage.contains("vet") || normalizedMessage.contains("veterinarian")) {
          return "I can help with veterinarian information. Ask for vets by specialty, name, or availability.";
      }

      if (normalizedMessage.contains("visit") || normalizedMessage.contains("appointment")) {
          return "I can help with visit information. Tell me the pet or owner, and what visit details you need.";
      }

      return "I am here and ready to help with Animal Clinic. Ask me about owners, pets, visits, or veterinarians.";
  }

  private String normalizeQuery(String query) {
      if (query == null) {
          return "";
      }

      String message = query.trim();
      if (message.length() >= 2 && message.startsWith("\"") && message.endsWith("\"")) {
          message = message.substring(1, message.length() - 1);
      }

      return message.replace("\\\"", "\"")
          .replace("\\n", "\n")
          .trim();
  }
}
