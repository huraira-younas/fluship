part of 'file_manager_bloc.dart';

sealed class FileManagerEvent extends BaseBlocEvent {
  const FileManagerEvent({required super.name, super.onError, super.onSuccess});
}

class FileManagerInitialized extends FileManagerEvent {
  const FileManagerInitialized({super.onError, super.onSuccess})
    : super(name: 'File_Manager_Initialized');

  @override
  Map<String, dynamic> toJson() => {};
}

class FileManagerNavigateToSegment extends FileManagerEvent {
  const FileManagerNavigateToSegment({
    required this.index,
    super.onSuccess,
    super.onError,
  }) : super(name: 'File_Manager_Navigate_To_Segment');

  final int index;

  @override
  Map<String, dynamic> toJson() => {'index': index};
}

class FileManagerOpenDirectory extends FileManagerEvent {
  const FileManagerOpenDirectory({
    required this.path,
    super.onSuccess,
    super.onError,
  }) : super(name: 'File_Manager_Open_Directory');

  final String path;

  @override
  Map<String, dynamic> toJson() => {'path': path};
}

class FileManagerToggleSelection extends FileManagerEvent {
  const FileManagerToggleSelection({
    required this.path,
    super.onSuccess,
    super.onError,
  }) : super(name: 'File_Manager_Toggle_Selection');

  final String path;

  @override
  Map<String, dynamic> toJson() => {'path': path};
}

class FileManagerSelectAll extends FileManagerEvent {
  const FileManagerSelectAll({super.onSuccess, super.onError})
    : super(name: 'File_Manager_Select_All');

  @override
  Map<String, dynamic> toJson() => {};
}

class FileManagerClearSelection extends FileManagerEvent {
  const FileManagerClearSelection({super.onSuccess, super.onError})
    : super(name: 'File_Manager_Clear_Selection');

  @override
  Map<String, dynamic> toJson() => {};
}

class FileManagerDeleteSelected extends FileManagerEvent {
  const FileManagerDeleteSelected({super.onSuccess, super.onError})
    : super(name: 'File_Manager_Delete_Selected');

  @override
  Map<String, dynamic> toJson() => {};
}
