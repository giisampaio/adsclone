/// Direção criativa (UI + payload para `mode: generate`).
/// Campos `direction` e `changes` alinham com a Edge Function deployada.
class CreativeDirectionItem {
  CreativeDirectionItem({
    required this.localId,
    required this.direction,
    required this.changes,
    required this.prompt,
    this.active = true,
  });

  final String localId;
  String direction;
  String changes;
  String prompt;
  bool active;

  static String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  factory CreativeDirectionItem.generated({
    required String direction,
    required String changes,
    required String prompt,
  }) {
    return CreativeDirectionItem(
      localId: _newId('g'),
      direction: direction,
      changes: changes,
      prompt: prompt,
      active: true,
    );
  }

  factory CreativeDirectionItem.manual({
    required String direction,
    required String changes,
    required String prompt,
  }) {
    return CreativeDirectionItem(
      localId: _newId('m'),
      direction: direction,
      changes: changes,
      prompt: prompt,
      active: true,
    );
  }

  Map<String, dynamic> toWireJson() => {
        'id': localId,
        'direction': direction,
        'changes': changes,
        'prompt': prompt,
        'active': active,
      };
}
