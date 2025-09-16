module MyModule::GreetingCards {
    use aptos_framework::signer;
    use std::string::String;
    use aptos_framework::event;

    /// Struct representing an NFT greeting card
    struct GreetingCard has store, key {
        id: u64,                    // Unique card ID
        title: String,              // Card title (e.g., "Happy Birthday!")
        message: String,            // Personal message content
        sender: address,            // Address of card sender
        recipient: address,         // Address of card recipient
        theme: String,              // Card theme (birthday, love, holiday, etc.)
        created_at: u64,            // Timestamp when card was created
    }

    /// Resource to track card creation for each user
    struct CardRegistry has key {
        next_card_id: u64,          // Counter for generating unique card IDs
        total_cards_sent: u64,      // Total number of cards sent by this user
    }

    /// Event emitted when a new greeting card is created and sent
    #[event]
    struct CardSentEvent has drop, store {
        card_id: u64,
        sender: address,
        recipient: address,
        title: String,
        theme: String,
    }

    /// Resource to hold event handle for the sender
    struct CardEventHolder has key {
        sent_events: event::EventHandle<CardSentEvent>,
    }

    /// Function to create and send an NFT greeting card to recipient
    public fun create_and_send_card(
        sender: &signer,
        recipient: address,
        title: String,
        message: String,
        theme: String,
        timestamp: u64
    ) acquires CardRegistry, CardEventHolder {
        let sender_addr = signer::address_of(sender);

        // Initialize CardRegistry if not exists
        if (!exists<CardRegistry>(sender_addr)) {
            move_to(sender, CardRegistry {
                next_card_id: 1,
                total_cards_sent: 0,
            });
        };



        // Update registry
        let registry = borrow_global_mut<CardRegistry>(sender_addr);
        let card_id = registry.next_card_id;
        registry.next_card_id = card_id + 1;
        registry.total_cards_sent = registry.total_cards_sent + 1;

        // Create greeting card
        let greeting_card = GreetingCard {
            id: card_id,
            title,
            message,
            sender: sender_addr,
            recipient,
            theme,
            created_at: timestamp,
        };

        // Transfer card to recipient
        move_to(sender, greeting_card);

        // Emit card sent event
        let event_holder = borrow_global_mut<CardEventHolder>(sender_addr);
        event::emit_event(&mut event_holder.sent_events, CardSentEvent {
            card_id,
            sender: sender_addr,
            recipient,
            title,
            theme,
        });
    }

    /// Function to retrieve greeting card details by card owner
    public fun get_card_details(card_owner: address): (u64, String, String, address, address, String, u64) acquires GreetingCard {
        let card = borrow_global<GreetingCard>(card_owner);
        (
            card.id,
            card.title,
            card.message,
            card.sender,
            card.recipient,
            card.theme,
            card.created_at
        )
    }
}
